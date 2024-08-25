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
ORDER BY ad_month
