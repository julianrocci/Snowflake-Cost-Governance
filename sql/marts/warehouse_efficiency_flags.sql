-- Flags warehouses with inefficient compute usage patterns
-- based on utilization, idle time, and wake-up behavior.
-- This model is used to prioritize cost optimization actions.

WITH warehouse_metrics AS (

    SELECT
        warehouse_name,
        team,
        workload,
        environment,

        COUNT(DISTINCT usage_date)                         AS active_days,

        SUM(billed_seconds)                                AS total_billed_seconds,
        SUM(idle_seconds)                                  AS total_idle_seconds,

        AVG(utilization_ratio)                             AS avg_utilization_ratio,

        SUM(CASE WHEN is_wakeup = 1 THEN 1 ELSE 0 END)     AS wakeup_count

    FROM {{ ref('warehouse_cost_attribution') }}
    GROUP BY 1,2,3,4

)

SELECT
    warehouse_name,
    team,
    workload,
    environment,

    active_days,
    total_billed_seconds,
    total_idle_seconds,
    avg_utilization_ratio,
    wakeup_count,

    -- Efficiency flags
    CASE
        WHEN avg_utilization_ratio < 0.30 THEN 1
        ELSE 0
    END AS low_utilization_flag,

    CASE
        WHEN wakeup_count > active_days * 3 THEN 1
        ELSE 0
    END AS high_wakeup_flag,

    CASE
        WHEN avg_utilization_ratio < 0.30
          OR wakeup_count > active_days * 3
        THEN 1
        ELSE 0
    END AS optimization_candidate_flag

FROM warehouse_metrics;