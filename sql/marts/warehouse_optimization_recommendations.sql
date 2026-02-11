-- Generate Snowflake warehouse cost optimization recommendations
-- based on utilization, idle time, wakeup behavior, and potential multi-cluster scaling.

SELECT
    warehouse_name,
    workload,
    usage_date,

    weighted_utilization_ratio,
    idle_ratio,
    wakeup_ratio,
    total_billed_seconds,
    total_active_query_seconds,

    CASE

        -- Potential multi-cluster over-scaling
        WHEN weighted_utilization_ratio > 0.60
             AND idle_ratio < 0.20
             AND total_billed_seconds > total_active_query_seconds * 1.5
            THEN 'REVIEW_MULTI_CLUSTER_CONFIGURATION'

        -- Very low utilization: warehouse likely oversized
        WHEN weighted_utilization_ratio < 0.30
            THEN 'DOWNSIZE_WAREHOUSE'

        -- High idle time: auto-suspend likely too high
        WHEN idle_ratio > 0.50
            THEN 'REDUCE_AUTO_SUSPEND_TIMEOUT'

        -- Frequent wakeups: inefficient triggering pattern
        WHEN wakeup_ratio > 0.40
            THEN 'INVESTIGATE_WAKEUP_QUERIES'

        ELSE NULL
    END AS optimization_action,

    CASE

        WHEN weighted_utilization_ratio > 0.60
             AND idle_ratio < 0.20
             AND total_billed_seconds > total_active_query_seconds * 1.5
            THEN 'High utilization with disproportionately high billed time. Possible excessive multi-cluster scaling.'

        WHEN weighted_utilization_ratio < 0.30
            THEN 'Warehouse spends most of its billed time underutilized. Consider downsizing.'

        WHEN idle_ratio > 0.50
            THEN 'More than half of billed compute time is idle. Review auto-suspend configuration.'

        WHEN wakeup_ratio > 0.40
            THEN 'High proportion of queries are waking up the warehouse. Investigate scheduling or polling patterns.'

        ELSE 'Warehouse operating within expected efficiency range.'
    END AS optimization_reason

FROM {{ ref('warehouse_efficiency_metrics') }}

WHERE weighted_utilization_ratio IS NOT NULL;
