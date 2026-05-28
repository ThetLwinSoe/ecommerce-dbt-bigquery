{{
    config(
        materialized='table',
        description='Customer segmentation with RFM scores and behavioural segments'
    )
}}

/*
    Mart: mart_customer_segments
    -----------------------------
    Full customer-level mart combining demographics, RFM scoring, 
    and behavioural segmentation.

    RFM Scoring (1-5 scale, 5 = best):
      - Recency : lower days = higher score (recent = better)
      - Frequency: more purchases = higher score
      - Monetary : more items = higher score

    RFM Segments:
      Champions       : R≥4, F≥4, M≥4
      Loyal Customers : F≥4
      At Risk         : R≤2, was frequent
      Lost            : R=1
      Promising       : R≥4, F≤2
*/

with rfm_base as (

    select * from {{ ref('int_customer_rfm_base') }}

),

scored as (

    select
        *,

        -- Recency score: 5 = purchased most recently
        ntile(5) over (order by recency_days desc)  as recency_score,

        -- Frequency score: 5 = most frequent
        ntile(5) over (order by frequency asc)      as frequency_score,

        -- Monetary score: 5 = highest volume
        ntile(5) over (order by monetary_value asc) as monetary_score

    from rfm_base

),

segmented as (

    select
        *,

        -- Combined RFM score (simple average * 10 for readability)
        round((recency_score + frequency_score + monetary_score) / 3.0, 1)
                                                    as rfm_combined_score,

        -- Segment labels
        case
            when recency_score >= 4
             and frequency_score >= 4
             and monetary_score  >= 4              then 'Champion'
            when frequency_score >= 4              then 'Loyal Customer'
            when recency_score   >= 4
             and frequency_score  <= 2             then 'Promising'
            when recency_score   >= 3
             and frequency_score  >= 3             then 'Potential Loyalist'
            when recency_score   <= 2
             and frequency_score  >= 3             then 'At Risk'
            when recency_score   =  1              then 'Lost'
            else                                        'Needs Attention'
        end                                         as rfm_segment

    from scored

)

select
    customer_id,
    gender,
    age_band,
    tenure_segment,
    first_purchase_date,
    last_purchase_date,
    recency_days,
    frequency,
    monetary_value,
    unique_products_purchased,
    total_transactions,
    recency_score,
    frequency_score,
    monetary_score,
    rfm_combined_score,
    rfm_segment
from segmented
order by rfm_combined_score desc
