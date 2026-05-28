{{
    config(
        materialized='view',
        description='Per-customer RFM (Recency, Frequency, Monetary) base metrics'
    )
}}

/*
    Intermediate model: int_customer_rfm_base
    ------------------------------------------
    Computes raw RFM values per customer prior to scoring.

    - Recency  : days since last purchase (lower = better)
    - Frequency: total number of distinct purchase dates
    - Monetary : total items purchased across all baskets

    Reference date is the max date in the dataset (2019-06-19).
    In production, replace with current_date().
*/

with transactions as (

    select * from {{ ref('int_customer_transactions') }}

),

rfm_raw as (

    select
        customer_id,
        gender,
        age_band,
        tenure_segment,

        -- Recency: days since last purchase
        date_diff(
            date '2019-06-19',        -- snapshot date = max date in dataset
            max(basket_date),
            day
        )                                                   as recency_days,

        -- Frequency: number of distinct purchase dates
        count(distinct basket_date)                         as frequency,

        -- Monetary: total basket items (proxy for volume since no price data)
        sum(basket_count)                                   as monetary_value,

        -- Supporting metrics
        min(basket_date)                                    as first_purchase_date,
        max(basket_date)                                    as last_purchase_date,
        count(distinct product_id)                          as unique_products_purchased,
        count(distinct basket_id)                           as total_transactions

    from transactions
    group by 1, 2, 3, 4

)

select * from rfm_raw
