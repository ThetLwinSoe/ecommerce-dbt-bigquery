/*
    Singular test: assert_basket_count_minimum
    -------------------------------------------
    Business rule: basket_count must always be >= 2
    (minimum order in this system is 2 items).
    This test fails if any row has basket_count < 2.
*/

select
    basket_id,
    customer_id,
    product_id,
    basket_date,
    basket_count
from {{ ref('stg_basket_details') }}
where basket_count < 2
