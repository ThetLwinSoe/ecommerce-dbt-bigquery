{{
    config(
        materialized='table',
        description='Product co-purchase affinity — which products are bought together'
    )
}}

/*
    Mart: mart_product_affinity
    ----------------------------
    Finds products frequently purchased together by the same customer
    within the same day (basket-level co-occurrence).

    This is a simplified market basket analysis:
      - support      = % of customers who bought both products
      - lift         = how much more likely to buy together vs independently
      - co_purchases = raw count of customer-days where both appear

    Note: Only pairs appearing 10+ times are included to reduce noise.
*/

with baskets as (

    select
        customer_id,
        basket_date,
        product_id
    from {{ ref('int_customer_transactions') }}

),

-- Self-join baskets to get pairs bought same day by same customer
pairs as (

    select
        a.product_id    as product_a,
        b.product_id    as product_b,
        count(distinct concat(
            cast(a.customer_id as string), '-',
            cast(a.basket_date as string)
        ))              as co_purchases

    from baskets a
    inner join baskets b
        on  a.customer_id  = b.customer_id
        and a.basket_date  = b.basket_date
        and a.product_id   < b.product_id  -- avoid duplicates and self-pairs

    group by 1, 2
    having co_purchases >= 10             -- minimum support threshold

),

total_baskets as (
    select count(distinct concat(
        cast(customer_id as string), '-',
        cast(basket_date as string)
    )) as n_baskets
    from baskets
),

product_totals as (
    select
        product_id,
        count(distinct concat(
            cast(customer_id as string), '-',
            cast(basket_date as string)
        )) as product_baskets
    from baskets
    group by 1
),

with_metrics as (

    select
        p.product_a,
        p.product_b,
        p.co_purchases,
        ta.product_baskets  as product_a_baskets,
        tb.product_baskets  as product_b_baskets,
        total.n_baskets,

        -- Support: % of baskets containing both
        round(p.co_purchases * 100.0 / total.n_baskets, 4)
                            as support_pct,

        -- Lift: actual co-occurrence / expected if independent
        round(
            (p.co_purchases * 1.0 / total.n_baskets)
            / (
                (ta.product_baskets * 1.0 / total.n_baskets)
                * (tb.product_baskets * 1.0 / total.n_baskets)
            ),
            2
        )                   as lift

    from pairs p
    join product_totals ta  on p.product_a = ta.product_id
    join product_totals tb  on p.product_b = tb.product_id
    cross join total_baskets total

)

select
    product_a,
    product_b,
    co_purchases,
    support_pct,
    lift,
    case
        when lift >= 2  then 'Strong Affinity'
        when lift >= 1.5 then 'Moderate Affinity'
        else                  'Weak Affinity'
    end                 as affinity_label

from with_metrics
order by lift desc, co_purchases desc
