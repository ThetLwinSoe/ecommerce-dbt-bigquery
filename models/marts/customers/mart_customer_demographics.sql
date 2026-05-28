{{
    config(
        materialized='table',
        description='Customer demographics vs purchase behaviour summary'
    )
}}

/*
    Mart: mart_customer_demographics
    ----------------------------------
    Aggregates purchase behaviour by demographic groups.
    Shows how age band, gender, and tenure segment correlate
    with purchasing patterns.
*/

with transactions as (

    select * from {{ ref('int_customer_transactions') }}
    where is_gdpr_deleted = false    -- exclude GDPR-deleted customers

),

by_gender as (

    select
        'gender'                                    as dimension,
        gender                                      as segment_value,
        count(distinct customer_id)                 as customer_count,
        count(distinct basket_id)                   as total_transactions,
        sum(basket_count)                           as total_items,
        round(avg(basket_count), 2)                 as avg_basket_size,
        round(sum(basket_count) * 1.0
            / nullif(count(distinct customer_id), 0), 2)
                                                    as avg_items_per_customer,
        count(distinct product_id)                  as unique_products

    from transactions
    group by 1, 2

),

by_age_band as (

    select
        'age_band'                                  as dimension,
        coalesce(age_band, 'Unknown')               as segment_value,
        count(distinct customer_id)                 as customer_count,
        count(distinct basket_id)                   as total_transactions,
        sum(basket_count)                           as total_items,
        round(avg(basket_count), 2)                 as avg_basket_size,
        round(sum(basket_count) * 1.0
            / nullif(count(distinct customer_id), 0), 2)
                                                    as avg_items_per_customer,
        count(distinct product_id)                  as unique_products

    from transactions
    group by 1, 2

),

by_tenure as (

    select
        'tenure_segment'                            as dimension,
        coalesce(tenure_segment, 'Unknown')         as segment_value,
        count(distinct customer_id)                 as customer_count,
        count(distinct basket_id)                   as total_transactions,
        sum(basket_count)                           as total_items,
        round(avg(basket_count), 2)                 as avg_basket_size,
        round(sum(basket_count) * 1.0
            / nullif(count(distinct customer_id), 0), 2)
                                                    as avg_items_per_customer,
        count(distinct product_id)                  as unique_products

    from transactions
    group by 1, 2

),

unioned as (

    select * from by_gender
    union all
    select * from by_age_band
    union all
    select * from by_tenure

)

select * from unioned
order by dimension, total_transactions desc
