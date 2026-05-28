{{
    config(
        materialized='view',
        description='Cleaned customer demographic data with anomalies handled'
    )
}}

/*
    Staging model: stg_customer_details
    -------------------------------------
    Source : ecommerce_raw.customer_details
    Purpose: 
      - Normalise gender values
      - Cap/null anomalous ages (negatives, values > 100)
      - Flag GDPR-deleted customers (kvkktalepsilindi)
      - Cast data types
    
    Data Quality Notes:
      - customer_age has values like 2022 (likely birth year entered by mistake)
        and negative values — these are set to NULL
      - 'kvkktalepsilindi' is a Turkish GDPR deletion flag (KVKK = Turkish GDPR)
      - 8 customers flagged as kvkktalepsilindi are excluded from PII analysis
*/

with source as (

    select * from {{ source('ecommerce_raw', 'customer_details') }}

),

cleaned as (

    select
        -- Keys
        cast(customer_id as int64)                                as customer_id,

        -- Gender normalisation
        case
            when upper(trim(sex)) = 'MALE'                       then 'Male'
            when upper(trim(sex)) = 'FEMALE'                     then 'Female'
            when trim(sex) = 'kvkktalepsilindi'                  then 'GDPR_Deleted'
            else                                                       'Unknown'
        end                                                       as gender,

        -- GDPR deletion flag
        case
            when trim(sex) = 'kvkktalepsilindi'                  then true
            else                                                       false
        end                                                       as is_gdpr_deleted,

        -- Age cleaning:
        --   Valid range: 18–100
        --   Values > 100 could be birth years (e.g. 2022) or typos → NULL
        --   Negative values → NULL
        case
            when cast(customer_age as float64) between 18 and 100
                 then cast(customer_age as int64)
            else null
        end                                                       as customer_age,

        -- Age banding (for segmentation)
        case
            when cast(customer_age as float64) between 18 and 24 then '18-24'
            when cast(customer_age as float64) between 25 and 34 then '25-34'
            when cast(customer_age as float64) between 35 and 44 then '35-44'
            when cast(customer_age as float64) between 45 and 54 then '45-54'
            when cast(customer_age as float64) between 55 and 64 then '55-64'
            when cast(customer_age as float64) >= 65              then '65+'
            else                                                       'Unknown'
        end                                                       as age_band,

        -- Tenure in days (already clean)
        cast(tenure as int64)                                     as tenure_days,

        -- Tenure segments
        case
            when cast(tenure as int64) <= 30  then 'New (≤30 days)'
            when cast(tenure as int64) <= 60  then 'Growing (31-60 days)'
            when cast(tenure as int64) <= 90  then 'Established (61-90 days)'
            else                                   'Loyal (90+ days)'
        end                                                       as tenure_segment,

        -- Audit
        current_timestamp()                                       as _loaded_at

    from source
    where customer_id is not null

)

select * from cleaned
