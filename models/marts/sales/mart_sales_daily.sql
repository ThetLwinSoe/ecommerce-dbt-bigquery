{{
    config(
        materialized='table',
        description='Daily sales performance metrics — primary sales trend mart'
    )
}}

/*
    Mart: mart_sales_daily
    ----------------------
    Daily aggregated sales metrics for trend analysis and dashboarding.
    Best used for: time-series charts, day-over-day comparisons, weekly patterns.
*/

with transactions as (

    select * from {{ ref('int_customer_transactions') }}

),

daily_metrics as (

    select
        basket_date,
        day_name,
        day_of_week,

        -- Volume metrics
        count(distinct basket_id)           as total_transactions,
        count(distinct customer_id)         as unique_customers,
        count(distinct product_id)          as unique_products,
        sum(basket_count)                   as total_items_sold,

        -- Average metrics
        round(avg(basket_count), 2)         as avg_basket_size,
        round(
            sum(basket_count) * 1.0
            / nullif(count(distinct customer_id), 0),
            2
        )                                   as avg_items_per_customer,

        -- New vs returning customers (first purchase on that day)
        countif(
            basket_date = first_purchase_date_flag
        )                                   as new_customers_estimate

    from (
        select
            *,
            min(basket_date) over (
                partition by customer_id
            ) as first_purchase_date_flag
        from transactions
    )
    group by 1, 2, 3

),

with_rolling as (

    select
        *,
        -- 7-day rolling average of transactions
        avg(total_transactions) over (
            order by basket_date
            rows between 6 preceding and current row
        )                                   as rolling_7d_transactions,

        -- Cumulative totals
        sum(total_items_sold) over (
            order by basket_date
        )                                   as cumulative_items_sold,

        sum(unique_customers) over (
            order by basket_date
        )                                   as cumulative_customers

    from daily_metrics

)

select * from with_rolling
order by basket_date
