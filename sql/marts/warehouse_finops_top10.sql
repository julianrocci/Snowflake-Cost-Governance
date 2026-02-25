-- Top 10 most costly warehouses per month
-- With alert flag

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
        ) AS rank_per_month,

        CASE
            WHEN estimated_monthly_waste_usd > 1000
                 AND avg_monthly_waste_ratio > 0.30
            THEN TRUE
            ELSE FALSE
        END AS requires_immediate_action

    FROM monthly_summary
) ranked
WHERE rank_per_month <= 10
ORDER BY usage_month DESC, rank_per_month;