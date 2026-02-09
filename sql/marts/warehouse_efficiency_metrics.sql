-- Expose normalized warehouse efficiency metrics
-- including utilization, idle time, and wakeup behavior
-- to support Snowflake cost governance decisions.

WITH query_wakeup_stats AS (
    SELECT
        warehouse_name,
        DATE(start_time) AS usage_date,

        COUNT(*) AS total_query_count,
        SUM(is_wakeup) AS wakeup_query_count

    FROM {{ ref('warehouse_query_wakeups') }}
    GROUP BY warehouse_name, DATE(start_time)
)

SELECT
    c.warehouse_name,
    c.workload,
    c.usage_date,

    c.total_billed_seconds,
    c.total_active_query_seconds,
    c.total_idle_seconds,

    c.weighted_utilization_ratio,
    ROUND(
        c.total_idle_seconds / NULLIF(c.total_billed_seconds, 0),
        4
    ) AS idle_ratio,

    q.total_query_count,
    q.wakeup_query_count,

    ROUND(
        q.wakeup_query_count / NULLIF(q.total_query_count, 0),
        4
    ) AS wakeup_ratio

FROM {{ ref('warehouse_cost_attribution') }} c
LEFT JOIN query_wakeup_stats q
    ON c.warehouse_name = q.warehouse_name
   AND c.usage_date = q.usage_date;