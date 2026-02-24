-- Top 10 most costly warehouses per month
-- For management dashboard and alerting

WITH monthly_summary AS (
    SELECT *
    FROM {{ ref('warehouse_finops_monthly_summary') }}
)

SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY usage_month
            ORDER BY estimated_monthly_waste_usd DESC
        ) AS rank_per_month
    FROM monthly_summary
) ranked
WHERE rank_per_month <= 10
ORDER BY usage_month DESC, rank_per_month;