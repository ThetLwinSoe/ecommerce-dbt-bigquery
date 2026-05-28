/*
    Singular test: assert_no_future_dates
    --------------------------------------
    Business rule: basket_date should not be in the future
    relative to the dataset snapshot (2019-06-19).
    This guards against data pipeline errors injecting incorrect dates.
*/

select
    basket_id,
    customer_id,
    basket_date
from {{ ref('stg_basket_details') }}
where basket_date > date '2019-06-19'
