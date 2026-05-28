{{
    config(
        materialized='view',
        description='Joined basket transactions enriched with customer demographics'
    )
}}

/*
    Intermediate model: int_customer_transactions
    -----------------------------------------------
    Joins basket transactions with customer demographics.
    This is the core enriched fact table used by all mart models.

    Grain: One row per basket transaction (customer + product + date)
*/

with baskets as (

    select * from {{ ref('stg_basket_details') }}

),

customers as (

    select * from {{ ref('stg_customer_details') }}

),

joined as (

    select
        -- Transaction keys
        b.basket_id,
        b.customer_id,
        b.product_id,

        -- Date dimensions
        b.basket_date,
        extract(year  from b.basket_date)   as purchase_year,
        extract(month from b.basket_date)   as purchase_month,
        extract(week  from b.basket_date)   as purchase_week,
        extract(dayofweek from b.basket_date) as day_of_week,  -- 1=Sun, 7=Sat
        format_date('%A', b.basket_date)    as day_name,

        -- Transaction metrics
        b.basket_count,

        -- Customer demographics (with null-safe join)
        c.gender,
        c.customer_age,
        c.age_band,
        c.tenure_days,
        c.tenure_segment,
        c.is_gdpr_deleted,

        -- Flag whether this customer exists in the customer table
        case when c.customer_id is not null then true else false end
            as has_customer_profile

    from baskets b
    left join customers c
        on b.customer_id = c.customer_id

)

select * from joined
