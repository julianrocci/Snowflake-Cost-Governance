-- Generate actionable cost optimization recommendations per warehouse
-- based on observed utilization, idle time, and wakeup patterns.

WITH base AS (

    SELECT
        warehouse_name,
        workload,
        avg_utilization_ratio,
        idle_ratio,
        wakeup_ratio,
        total_idle_seconds,
        total_billed_seconds
    FROM {{ ref('warehouse_efficiency_flags') }}

),

recommendations AS (

    SELECT
        warehouse_name,
        workload,

        /* Recommendation type */
        CASE
            WHEN avg_utilization_ratio < 0.30
                THEN 'DOWNSIZE_WAREHOUSE'

            WHEN idle_ratio > 0.50
                THEN 'REDUCE_AUTO_SUSPEND_TIMEOUT'

            WHEN wakeup_ratio > 0.40
                 AND workload = 'BI'
                THEN 'DISABLE_AUTO_RESUME_FOR_BI'

            WHEN wakeup_ratio > 0.40
                 AND workload IN ('ANALYTICS', 'ELT')
                THEN 'BATCH_OR_CONSOLIDATE_QUERIES'

            ELSE NULL
        END AS recommendation_type,

        /* Human-readable reason */
        CASE
            WHEN avg_utilization_ratio < 0.30
                THEN 'Warehouse is significantly under-utilized on average'

            WHEN idle_ratio > 0.50
                THEN 'More than half of billed time is spent idle'

            WHEN wakeup_ratio > 0.40
                 AND workload = 'BI'
                THEN 'BI queries frequently wake up the warehouse causing idle-heavy billing'

            WHEN wakeup_ratio > 0.40
                 AND workload IN ('ANALYTICS', 'ELT')
                THEN 'Frequent isolated queries suggest batching opportunities'

            ELSE NULL
        END AS recommendation_reason,

        /* Expected impact */
        CASE
            WHEN avg_utilization_ratio < 0.30
                THEN 'Lower compute size with minimal performance impact'

            WHEN idle_ratio > 0.50
                THEN 'Reduced idle billing and faster warehouse suspension'

            WHEN wakeup_ratio > 0.40
                 AND workload = 'BI'
                THEN 'Avoid unnecessary warehouse wakeups for sporadic BI access'

            WHEN wakeup_ratio > 0.40
                 AND workload IN ('ANALYTICS', 'ELT')
                THEN 'Reduced wakeups and better compute efficiency'

            ELSE NULL
        END AS expected_impact,

        /* Confidence score (simple heuristic) */
        CASE
            WHEN avg_utilization_ratio < 0.20 THEN 'HIGH'
            WHEN idle_ratio > 0.60 THEN 'HIGH'
            WHEN wakeup_ratio > 0.50 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS confidence_level

    FROM base
)

SELECT *
FROM recommendations
WHERE recommendation_type IS NOT NULL;