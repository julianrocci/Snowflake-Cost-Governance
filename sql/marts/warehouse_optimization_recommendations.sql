-- Generate Snowflake warehouse cost optimization recommendations
-- including priority and estimated savings.

SELECT
    warehouse_name,
    workload,
    usage_date,

    weighted_utilization_ratio,
    idle_ratio,
    wakeup_ratio,
    total_billed_seconds,
    total_active_query_seconds,
    total_idle_seconds,

    avg_cluster_count,
    max_cluster_count_seen,
    is_multi_cluster_active,

    --------------------------------------------------------------------
    -- Optimization Action
    --------------------------------------------------------------------
    CASE
        WHEN is_multi_cluster_active = TRUE
            THEN 'REVIEW_MULTI_CLUSTER_CONFIGURATION'

        WHEN weighted_utilization_ratio < 0.30
            THEN 'DOWNSIZE_WAREHOUSE'

        WHEN idle_ratio > 0.50
            THEN 'REDUCE_AUTO_SUSPEND_TIMEOUT'

        WHEN wakeup_ratio > 0.40
            THEN 'INVESTIGATE_WAKEUP_QUERIES'

        ELSE NULL
    END AS optimization_action,

    --------------------------------------------------------------------
    -- Optimization Priority
    --------------------------------------------------------------------
    CASE
        WHEN is_multi_cluster_active = TRUE THEN 'HIGH'
        WHEN weighted_utilization_ratio < 0.30 THEN 'HIGH'
        WHEN idle_ratio > 0.50 THEN 'MEDIUM'
        WHEN wakeup_ratio > 0.40 THEN 'LOW'
        ELSE 'NONE'
    END AS optimization_priority,

    --------------------------------------------------------------------
    -- Estimated Savings (Seconds)
    --------------------------------------------------------------------
    CASE
        WHEN is_multi_cluster_active = TRUE
            THEN total_billed_seconds * (avg_cluster_count - 1) / NULLIF(avg_cluster_count, 0)

        WHEN weighted_utilization_ratio < 0.30
            THEN total_billed_seconds * 0.30

        WHEN idle_ratio > 0.50
            THEN total_idle_seconds

        WHEN wakeup_ratio > 0.40
            THEN total_billed_seconds * 0.10

        ELSE 0
    END AS estimated_savings_seconds

FROM {{ ref('warehouse_efficiency_metrics') }}

WHERE weighted_utilization_ratio IS NOT NULL;