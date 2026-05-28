{{
    config(
        materialized='table',
        description='Weekly sales performance summary'
    )
}}

/*
    Mart: mart_sales_weekly
    -------------------------
    Weekly roll-up of sales performance. 
    Useful for week-over-week trend and cohort comparisons.
*/

with transactions as (

    select * from {{ ref('int_customer_transactions') }}

),

weekly as (

    select
        purchase_year,
        purchase_week,
        min(basket_date)                            as week_start_date,
        max(basket_date)                            as week_end_date,

        count(distinct basket_id)                   as total_transactions,
        count(distinct customer_id)                 as unique_customers,
        count(distinct product_id)                  as unique_products_sold,
        sum(basket_count)                           as total_items_sold,
        round(avg(basket_count), 2)                 as avg_basket_size,

        -- Day with most sales that week
        approx_top_count(day_name, 1)[offset(0)].value
                                                    as busiest_day

    from transactions
    group by 1, 2

),

with_wow as (

    select
        *,
        lag(total_transactions) over (
            order by purchase_year, purchase_week
        )                                           as prev_week_transactions,

        round(
            safe_divide(
                total_transactions
                - lag(total_transactions) over (
                    order by purchase_year, purchase_week
                ),
                lag(total_transactions) over (
                    order by purchase_year, purchase_week
                )
            ) * 100,
            1
        )                                           as wow_transactions_pct_change

    from weekly

)

select * from with_wow
order by purchase_year, purchase_week
