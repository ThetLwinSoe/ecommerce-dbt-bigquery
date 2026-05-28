# E-Commerce Analytics — DBT + BigQuery Portfolio Project

## Project Overview

This project transforms raw e-commerce transaction data into clean,
analytics-ready data marts using **dbt (Data Build Tool)** on **Google BigQuery**.

It demonstrates end-to-end data modelling best practices including:
- Raw data ingestion and cleaning
- Layered modelling (Staging → Intermediate → Marts)
- RFM customer segmentation
- Product affinity / market basket analysis
- Data quality testing
- Full documentation via dbt docs

---

## Data Sources

| Table | Rows | Description |
|---|---|---|
| `basket_details` | 15,000 | Customer–product transactions (May–Jun 2019) |
| `customer_details` | 20,000 | Customer demographics (age, gender, tenure) |

---

## Model Layers

### Staging
Clean and type-cast raw source data. No business logic.

| Model | Description |
|---|---|
| `stg_basket_details` | Cleaned transactions with surrogate key |
| `stg_customer_details` | Cleaned customers — age outliers nulled, gender normalised, GDPR flags |

### Intermediate
Join and enrich — business logic lives here.

| Model | Description |
|---|---|
| `int_customer_transactions` | Transactions enriched with customer demographics |
| `int_customer_rfm_base` | Per-customer Recency, Frequency, Monetary raw metrics |

### Marts
Analytics-ready aggregated tables for BI tools.

| Model | Layer | Description |
|---|---|---|
| `mart_sales_daily` | Sales | Daily KPIs + 7-day rolling avg |
| `mart_sales_weekly` | Sales | Weekly roll-up + WoW % change |
| `mart_customer_segments` | Customers | RFM scoring + segment labels |
| `mart_customer_demographics` | Customers | Behaviour by gender / age / tenure |
| `mart_product_performance` | Products | Product volume rankings + tiers |
| `mart_product_affinity` | Products | Co-purchase pairs with lift scores |

---

## Key Design Decisions

1. **Surrogate keys** generated via `dbt_utils.generate_surrogate_key` to handle
   composite natural keys in basket data.

2. **Age cleaning**: `customer_age` values outside 18–100 are nulled. The raw data
   contains entries like `2022` (likely birth year entered accidentally) and negative
   values — a common real-world data quality issue.

3. **GDPR handling**: The value `kvkktalepsilindi` in the `sex` column is a Turkish
   GDPR deletion marker (KVKK). These customers are flagged and excluded from
   demographic analyses.

4. **RFM scoring**: Quintile-based (NTILE 5) so scores are always relative to the
   dataset — no hard-coded thresholds that break on new data.

5. **Monetary proxy**: No price data available, so `basket_count` (items purchased)
   is used as the monetary proxy.
