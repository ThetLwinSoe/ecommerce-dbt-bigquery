{{
    config(
        materialized='table',
        description='Product-level performance metrics and rankings'
    )
}}

/*
    Mart: mart_product_performance
    --------------------------------
    Product-level aggregation showing volume performance,
    customer reach, and purchase frequency patterns.
*/

with transactions as (

    select * from {{ ref('int_customer_transactions') }}

),

product_stats as (

    select
        product_id,

        -- Volume metrics
        count(distinct basket_id)                   as total_transactions,
        sum(basket_count)                           as total_items_sold,
        count(distinct customer_id)                 as unique_buyers,
        count(distinct basket_date)                 as days_purchased,

        -- Basket metrics
        round(avg(basket_count), 2)                 as avg_basket_count,
        max(basket_count)                           as max_basket_count,

        -- Date range
        min(basket_date)                            as first_sold_date,
        max(basket_date)                            as last_sold_date,

        -- Gender split of buyers
        countif(gender = 'Male')                    as male_buyer_count,
        countif(gender = 'Female')                  as female_buyer_count,

        -- Age band of most common buyers
        approx_top_count(age_band, 1)[offset(0)].value
                                                    as top_buyer_age_band

    from transactions
    group by 1

),

ranked as (

    select
        *,

        -- Global rankings
        rank() over (order by total_items_sold desc)    as rank_by_volume,
        rank() over (order by unique_buyers desc)       as rank_by_reach,
        rank() over (order by total_transactions desc)  as rank_by_frequency,

        -- Volume tier (top 10% = Hero, next 20% = Strong, rest = Standard)
        case
            when percent_rank() over (
                order by total_items_sold
            ) >= 0.9                                then 'Hero'
            when percent_rank() over (
                order by total_items_sold
            ) >= 0.7                                then 'Strong'
            else                                        'Standard'
        end                                             as product_tier

    from product_stats

)

select * from ranked
order by rank_by_volume
