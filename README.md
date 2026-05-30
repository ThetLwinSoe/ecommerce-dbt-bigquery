# 🛒 E-Commerce Analytics — dbt + BigQuery Portfolio Project

> **End-to-end data modelling** of e-commerce transactions using **dbt Core** and **Google BigQuery** — from raw CSVs to analytics-ready data marts with RFM segmentation, product affinity, and sales trend analysis.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Dataset](#dataset)
- [Architecture](#architecture)
- [Model Catalogue](#model-catalogue)
- [Key Analyses](#key-analyses)
- [Data Quality](#data-quality)
- [Setup Guide](#setup-guide)
- [How to Run](#how-to-run)
- [Project Structure](#project-structure)

---

## Project Overview

This portfolio project demonstrates production-grade data engineering skills by building a full **ELT analytics pipeline** for an e-commerce business. Starting from two raw CSV files, the project delivers:

- ✅ **Layered data models** (Staging → Intermediate → Marts)
- ✅ **Customer RFM segmentation** (Recency, Frequency, Monetary)
- ✅ **Product affinity / market basket analysis**
- ✅ **Sales trend analysis** (daily & weekly with rolling averages)
- ✅ **Customer demographic analysis** (age, gender, tenure)
- ✅ **Data quality tests** (generic + custom singular tests)
- ✅ **Full dbt documentation** with column-level descriptions

---

## Tech Stack

| Tool | Purpose |
|---|---|
| **dbt Core 1.7+** | Data transformation & modelling |
| **Google BigQuery** | Cloud data warehouse |
| **dbt_utils** | Surrogate keys, date spines, utilities |
| **VS Code** | Development environment |
| **Git / GitHub** | Version control & portfolio showcase |

---

## Dataset

| File | Rows | Columns |
|---|---|---|
| `basket_details.csv` | 15,000 | customer_id, product_id, basket_date, basket_count |
| `customer_details.csv` | 20,000 | customer_id, sex, customer_age, tenure |

**Date range:** May 20 – June 19, 2019 (31 days)  
**Unique customers in transactions:** 13,871  
**Unique products:** 13,161

### Data Quality Issues Handled
| Issue | Column | Resolution |
|---|---|---|
| Age outliers (values like 2022, negatives) | `customer_age` | Nulled if outside 18–100 |
| GDPR deletion flag (`kvkktalepsilindi`) | `sex` | Flagged as `is_gdpr_deleted = true`, excluded from PII analyses |
| Unknown gender values | `sex` | Normalised to `'Unknown'` |
| Composite natural key needed | basket_details | Surrogate key generated via `dbt_utils` |

---

## Architecture

```
Raw CSVs (BigQuery)
        │
        ▼
┌─────────────────────────────────────┐
│           STAGING LAYER             │  ← Views, type casting, cleaning
│  stg_basket_details                 │
│  stg_customer_details               │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│        INTERMEDIATE LAYER           │  ← Views, joins, enrichment
│  int_customer_transactions          │
│  int_customer_rfm_base              │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│           MART LAYER                │  ← Tables, aggregations, BI-ready
│  mart_sales_daily                   │
│  mart_sales_weekly                  │
│  mart_customer_segments (RFM)       │
│  mart_customer_demographics         │
│  mart_product_performance           │
│  mart_product_affinity              │
└─────────────────────────────────────┘
```

---

## Model Catalogue

### 🟡 Staging Models
| Model | Materialisation | Description |
|---|---|---|
| `stg_basket_details` | View | Cleaned transactions, surrogate key added |
| `stg_customer_details` | View | Cleaned demographics, age bands, tenure segments, GDPR flag |

### 🟠 Intermediate Models
| Model | Materialisation | Description |
|---|---|---|
| `int_customer_transactions` | View | Transactions LEFT JOINed with customer demographics |
| `int_customer_rfm_base` | View | Per-customer RFM raw values before scoring |

### 🟢 Mart Models
| Model | Materialisation | Description |
|---|---|---|
| `mart_sales_daily` | Table | Daily KPIs + 7-day rolling avg + cumulative totals |
| `mart_sales_weekly` | Table | Weekly roll-up with WoW % change |
| `mart_customer_segments` | Table | RFM quintile scores + 7 segment labels |
| `mart_customer_demographics` | Table | Purchase behaviour by gender / age band / tenure |
| `mart_product_performance` | Table | Product rankings by volume, reach, frequency + tiers |
| `mart_product_affinity` | Table | Co-purchase pairs with support %, lift, affinity label |

---

## Key Analyses

### 1. RFM Customer Segmentation
Customers are scored 1–5 on three dimensions using **NTILE quintiles**:
- **Recency**: How recently did they purchase? (5 = most recent)
- **Frequency**: How many distinct purchase days? (5 = most frequent)
- **Monetary**: How many total items purchased? (5 = highest volume)

**Segments:**
| Segment | Definition |
|---|---|
| Champion | R≥4, F≥4, M≥4 — Best customers |
| Loyal Customer | F≥4 — Frequent buyers |
| Promising | R≥4, F≤2 — New but engaged |
| Potential Loyalist | R≥3, F≥3 |
| Needs Attention | Mid-tier |
| At Risk | R≤2, F≥3 — Were frequent, now inactive |
| Lost | R=1 — Haven't bought recently |

### 2. Product Affinity (Market Basket Analysis)
Uses basket-level co-occurrence to calculate:
- **Support %**: % of baskets containing both products
- **Lift**: How much more likely to be bought together vs. independently
  - Lift > 2.0 → Strong Affinity
  - Lift > 1.5 → Moderate Affinity

### 3. Sales Trends
- Daily transaction counts with **7-day rolling average** to smooth noise
- Week-over-week percentage change
- Busiest day identification per week

---

## Data Quality

**Generic tests (dbt built-in):**
- `not_null` on all key columns
- `unique` on primary keys
- `accepted_values` on categorical columns (gender, rfm_segment)
- `relationships` on foreign keys

**Custom singular tests:**
- `assert_basket_count_minimum` — basket_count must always be ≥ 2
- `assert_no_future_dates` — no basket_date beyond dataset snapshot

Run all tests:
```bash
dbt test
```

---

## Setup Guide

### Prerequisites
- Python 3.9+
- Google Cloud account with BigQuery enabled
- `gcloud` CLI installed and authenticated

### Step 1: Install dbt

```bash
pip install dbt-bigquery
```

### Step 2: Clone this repository

```bash
git clone https://github.com/YOUR_USERNAME/ecommerce-dbt-bigquery.git
cd ecommerce-dbt-bigquery
```

### Step 3: Authenticate with Google Cloud

```bash
gcloud auth application-default login
```

### Step 4: Load CSVs into BigQuery

In the **BigQuery Console**:
1. Create a dataset called `ecommerce_raw` in your project
2. Upload `basket_details.csv` → table `basket_details`
3. Upload `customer_details.csv` → table `customer_details`
4. Set schema auto-detect = ON for both

### Step 5: Configure your profile

Copy `profiles.yml` to your `~/.dbt/` folder:

```bash
cp profiles.yml ~/.dbt/profiles.yml
```

Then edit `~/.dbt/profiles.yml` and replace `YOUR_GCP_PROJECT_ID` with your actual GCP project ID.

Also update `models/staging/sources.yml` — replace `YOUR_GCP_PROJECT_ID` with your project ID.

### Step 6: Install dbt packages

```bash
dbt deps
```

### Step 7: Verify connection

```bash
dbt debug
```

---

## How to Run

```bash
# Run all models
dbt run

# Run only staging models
dbt run --select staging

# Run a specific model and all its dependencies
dbt run --select +mart_customer_segments

# Run all tests
dbt test

# Run tests for a specific model
dbt test --select mart_customer_segments

# Generate and serve documentation
dbt docs generate
dbt docs serve

# Run everything (models + tests)
dbt build
```

---

## Project Structure

```
ecommerce_dbt/
├── dbt_project.yml                    # Project config & materialisation settings
├── profiles.yml                       # BigQuery connection profile (template)
├── packages.yml                       # dbt_utils dependency
│
├── models/
│   ├── staging/
│   │   ├── sources.yml                # Source table definitions + tests
│   │   ├── stg_models.yml             # Staging model docs + tests
│   │   ├── stg_basket_details.sql
│   │   └── stg_customer_details.sql
│   │
│   ├── intermediate/
│   │   ├── int_models.yml
│   │   ├── int_customer_transactions.sql
│   │   └── int_customer_rfm_base.sql
│   │
│   └── marts/
│       ├── mart_models.yml
│       ├── sales/
│       │   ├── mart_sales_daily.sql
│       │   └── mart_sales_weekly.sql
│       ├── customers/
│       │   ├── mart_customer_segments.sql
│       │   └── mart_customer_demographics.sql
│       └── products/
│           ├── mart_product_performance.sql
│           └── mart_product_affinity.sql
│
├── macros/
│   ├── test_is_positive.sql           # Custom generic test
│   └── get_date_spine.sql             # Date spine utility
│
├── tests/
│   ├── assert_basket_count_minimum.sql
│   └── assert_no_future_dates.sql
│
├── analyses/
│   └── exploratory_eda.sql            # Ad-hoc EDA queries
│
└── docs/
    └── overview.md                    # Project documentation
```

---

## Author

Built as a portfolio project to demonstrate dbt + BigQuery data engineering skills.  
Connect on [LinkedIn](https://www.linkedin.com/in/thetlwin/) 🔗

---

*Built with ❤️ using dbt Core + Google BigQuery*
