/*
    Analysis: Exploratory Data Analysis
    -------------------------------------
    Ad-hoc queries used during project design phase.
    Run with: dbt compile --select analyses/exploratory_eda.sql
    Then execute the compiled SQL in BigQuery console.

    These are NOT part of the model DAG — for documentation purposes only.
*/

-- ── 1. Dataset Overview ──────────────────────────────────────────────────────
select
    (select count(*) from {{ ref('stg_basket_details') }})   as basket_rows,
    (select count(*) from {{ ref('stg_customer_details') }}) as customer_rows,
    (select min(basket_date) from {{ ref('stg_basket_details') }}) as date_min,
    (select max(basket_date) from {{ ref('stg_basket_details') }}) as date_max
;

-- ── 2. Gender Distribution ───────────────────────────────────────────────────
select
    gender,
    count(*)                                    as customer_count,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct
from {{ ref('stg_customer_details') }}
group by 1
order by 2 desc
;

-- ── 3. Age Distribution (valid ages only) ────────────────────────────────────
select
    age_band,
    count(*)                                    as customers,
    round(avg(tenure_days), 0)                  as avg_tenure_days
from {{ ref('stg_customer_details') }}
where customer_age is not null
group by 1
order by 1
;

-- ── 4. Top 10 Products by Volume ────────────────────────────────────────────
select
    product_id,
    total_items_sold,
    unique_buyers,
    rank_by_volume,
    product_tier
from {{ ref('mart_product_performance') }}
order by rank_by_volume
limit 10
;

-- ── 5. RFM Segment Distribution ─────────────────────────────────────────────
select
    rfm_segment,
    count(*)                                    as customers,
    round(avg(recency_days), 1)                 as avg_recency_days,
    round(avg(frequency), 1)                    as avg_frequency,
    round(avg(monetary_value), 1)               as avg_monetary
from {{ ref('mart_customer_segments') }}
group by 1
order by customers desc
;
