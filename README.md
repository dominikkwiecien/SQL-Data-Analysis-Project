# SQL Data Analysis Project

## Project Overview

This project demonstrates the application of advanced SQL techniques, focusing on working with date functions and window functions. The task was to analyze advertising data from Facebook and Google Ads, calculating key performance indicators (KPIs) and comparing them month over month.

The primary objective was to showcase proficiency in SQL by manipulating data, performing complex calculations, and generating insights that can inform marketing strategies.

## Project Details

### Task Description

The goal of this project was to:

1. **Utilize CTE (Common Table Expressions):**

   - Create a sample dataset using a CTE from a previous task that includes data fields such as `ad_date`, `url_parameters`, `spend`, `impressions`, `reach`, `clicks`, `leads`, and `value`.

2. **Generate a New Dataset:**

   - Use the CTE to create a new dataset (another CTE) that aggregates data by month and UTM campaign. The dataset includes fields such as:
     - `ad_month`: The first day of the month from `ad_date`.
     - `utm_campaign`, `total_spend`, `total_impressions`, `total_clicks`, `total_value`, `CTR`, `CPC`, `CPM`, `ROMI`.

3. **Calculate Month-over-Month Differences:**
   - For each `utm_campaign` and `ad_month`, calculate the percentage change in `CPM`, `CTR`, and `ROMI` compared to the previous month.

### SQL Code Implementation

The following SQL query was implemented to achieve the project objectives:

```sql
WITH CTE AS (
    SELECT
        facebook_ads_basic_daily.ad_date,
        facebook_ads_basic_daily.url_parameters,
        COALESCE(facebook_ads_basic_daily.spend, 0) AS spend,
        COALESCE(facebook_ads_basic_daily.impressions, 0) AS impressions,
        COALESCE(facebook_ads_basic_daily.reach, 0) AS reach,
        COALESCE(facebook_ads_basic_daily.clicks, 0) AS clicks,
        COALESCE(facebook_ads_basic_daily.leads, 0) AS leads,
        COALESCE(facebook_ads_basic_daily.value, 0) AS value
    FROM
        facebook_ads_basic_daily
    JOIN
        facebook_adset ON facebook_ads_basic_daily.adset_id = facebook_adset.adset_id
    JOIN
        facebook_campaign ON facebook_ads_basic_daily.campaign_id = facebook_campaign.campaign_id
    JOIN
        google_ads_basic_daily ON facebook_campaign.campaign_name = google_ads_basic_daily.campaign_name
),
CTE2 AS (
    SELECT
        DATE(DATE_TRUNC('month', ad_date)) AS ad_month,
        CASE
            WHEN LOWER(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]*)')) = 'nan' THEN NULL
            ELSE LOWER(SUBSTRING(url_parameters FROM 'utm_campaign=([^&]*)'))
        END AS utm_campaign,
        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks,
        SUM(value) AS total_value,
        round(1.0 * SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS CPC,
        round(1.0 * SUM(spend) / NULLIF(SUM(impressions), 0), 2) * 1000 AS CPM,
        round(1.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 2) * 100 AS CTR,
        round(1.0 * SUM(value) / NULLIF(SUM(spend), 0), 2) * 100 AS ROMI
    FROM
        CTE
    GROUP BY
        ad_month, utm_campaign
)
SELECT
    ad_month,
    utm_campaign,
    total_spend,
    total_impressions,
    total_clicks,
    total_value,
    CTR,
    CPC,
    CPM,
    ROMI,
    COALESCE(round((CPM - LAG(CPM, 1) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) / NULLIF(LAG(CPM, 1) OVER (PARTITION BY utm_campaign ORDER BY ad_month), 0), 4), 0) * 100 AS CPM_diff,
    COALESCE(round((CTR - LAG(CTR, 1) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) / NULLIF(LAG(CTR, 1) OVER (PARTITION BY utm_campaign ORDER BY ad_month), 0), 4), 0) * 100 AS CTR_diff,
    COALESCE(round((ROMI - LAG(ROMI, 1) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) / NULLIF(LAG(ROMI, 1) OVER (PARTITION BY utm_campaign ORDER BY ad_month), 0), 4), 0) * 100 AS ROMI_diff
FROM
    CTE2
ORDER BY ad_month;
```

### Key Concepts Utilized

- **Common Table Expressions (CTE):** Used to simplify complex queries and make them more readable by breaking down the query into logical parts.
- **Window Functions:** Leveraged to calculate month-over-month differences in key metrics (CPM, CTR, ROMI).

- **Date Functions:** Employed to manipulate and aggregate data by month.

- **COALESCE Function:** Used to handle null values effectively, ensuring accurate calculations.

### Results and Insights

The analysis provided valuable insights into the performance of different UTM campaigns over time. By comparing the CPM, CTR, and ROMI metrics month over month, the analysis can help identify trends, highlight areas for improvement, and optimize marketing strategies.

### Conclusion

This project highlights the power of SQL in data analysis, particularly in handling time-series data and performing comparative analysis using advanced SQL features. The techniques demonstrated in this project can be applied to a wide range of data analysis scenarios, making it a valuable tool for data professionals.
