{{
    config(
        materialized='view',
        description='Cleaned and standardised basket transaction data'
    )
}}

/*
    Staging model: stg_basket_details
    ----------------------------------
    Source : ecommerce_raw.basket_details
    Purpose: Cast data types, rename for clarity, add surrogate key.
    No business logic here — just clean and conform.
*/

with source as (

    select * from {{ source('ecommerce_raw', 'basket_details') }}

),

renamed as (

    select
        -- Keys
        cast(customer_id  as int64)                   as customer_id,
        cast(product_id   as int64)                   as product_id,

        -- Dates
        cast(basket_date as date)           as basket_date,

        -- Measures
        cast(basket_count as int64)                   as basket_count,

        -- Audit columns
        current_timestamp()                           as _loaded_at

    from source
    where customer_id is not null
      and product_id  is not null
      and basket_date is not null

)

select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'product_id', 'basket_date']) }}
        as basket_id,
    *
from renamed
