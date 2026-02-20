-- Monthly FinOps Summary
-- Aggregates optimization impact at monthly level

WITH base AS (

    SELECT
        warehouse_name,
        DATE_TRUNC('month', usage_date) AS usage_month,

        estimated_waste_seconds,
        estimated_waste_ratio

    FROM {{ ref('warehouse_optimization_model') }}

)

SELECT
    warehouse_name,
    usage_month,

    SUM(estimated_waste_seconds) AS total_monthly_waste_seconds,

    AVG(estimated_waste_ratio) AS avg_monthly_waste_ratio,

    RANK() OVER (
        PARTITION BY usage_month
        ORDER BY SUM(estimated_waste_seconds) DESC
    ) AS monthly_waste_rank

FROM base

GROUP BY warehouse_name, usage_month
ORDER BY usage_month DESC, monthly_waste_rank;