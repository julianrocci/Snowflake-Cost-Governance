-- Generate Snowflake warehouse cost optimization recommendations
-- based on utilization, idle time, wakeup behavior, and multi-cluster activity.

SELECT
    warehouse_name,
    workload,
    usage_date,

    -- Core efficiency metrics
    weighted_utilization_ratio,
    idle_ratio,
    wakeup_ratio,
    total_billed_seconds,
    total_active_query_seconds,

    -- Multi-cluster signals
    avg_cluster_count,
    max_cluster_count_seen,
    is_multi_cluster_active,

    --------------------------------------------------------------------
    -- Optimization Action (Single prioritized recommendation)
    --------------------------------------------------------------------
    CASE

        -- 1️⃣ Multi-cluster scaling review
        WHEN is_multi_cluster_active = TRUE
            THEN 'REVIEW_MULTI_CLUSTER_CONFIGURATION'

        -- 2️⃣ Very low utilization: warehouse likely oversized
        WHEN weighted_utilization_ratio < 0.30
            THEN 'DOWNSIZE_WAREHOUSE'

        -- 3️⃣ High idle time: auto-suspend likely too high
        WHEN idle_ratio > 0.50
            THEN 'REDUCE_AUTO_SUSPEND_TIMEOUT'

        -- 4️⃣ Frequent wakeups: inefficient triggering pattern
        WHEN wakeup_ratio > 0.40
            THEN 'INVESTIGATE_WAKEUP_QUERIES'

        ELSE NULL
    END AS optimization_action,

    --------------------------------------------------------------------
    -- Optimization Explanation
    --------------------------------------------------------------------
    CASE

        WHEN is_multi_cluster_active = TRUE
            THEN 'Warehouse frequently scales beyond a single cluster. Review max_cluster_count and concurrency patterns.'

        WHEN weighted_utilization_ratio < 0.30
            THEN 'Warehouse spends most of its billed time underutilized. Consider downsizing.'

        WHEN idle_ratio > 0.50
            THEN 'More than half of billed compute time is idle. Review auto-suspend configuration.'

        WHEN wakeup_ratio > 0.40
            THEN 'High proportion of queries are waking up the warehouse. Investigate scheduling or polling patterns.'

        ELSE 'Warehouse operating within expected efficiency range.'
    END AS optimization_reason,

    --------------------------------------------------------------------
    -- Optimization Priority (Business Impact Level)
    --------------------------------------------------------------------
    CASE

        WHEN is_multi_cluster_active = TRUE
            THEN 'HIGH'

        WHEN weighted_utilization_ratio < 0.30
            THEN 'HIGH'

        WHEN idle_ratio > 0.50
            THEN 'MEDIUM'

        WHEN wakeup_ratio > 0.40
            THEN 'LOW'

        ELSE 'NONE'

    END AS optimization_priority

FROM {{ ref('warehouse_efficiency_metrics') }}

WHERE weighted_utilization_ratio IS NOT NULL;