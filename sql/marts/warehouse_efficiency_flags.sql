-- Enhanced warehouse efficiency metrics with weighted utilization
-- and estimated idle cost savings potential.

WITH warehouse_metrics AS (

    SELECT
        warehouse_name,
        team,
        workload,
        environment,

        COUNT(DISTINCT usage_date)                         AS active_days,

        SUM(billed_seconds)                                AS total_billed_seconds,
        SUM(idle_seconds)                                  AS total_idle_seconds,

        -- Weighted utilization (more accurate than simple average)
        SUM(billed_seconds - idle_seconds)
            / NULLIF(SUM(billed_seconds), 0)               AS weighted_utilization_ratio,

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
    weighted_utilization_ratio,
    wakeup_count,

    -- Optimization signals
    CASE
        WHEN weighted_utilization_ratio < 0.30 THEN 1
        ELSE 0
    END AS low_utilization_flag,

    CASE
        WHEN wakeup_count > active_days * 3 THEN 1
        ELSE 0
    END AS high_wakeup_flag,

    -- Conservative idle savings estimate (50% of idle)
    ROUND(total_idle_seconds * 0.5) AS potential_idle_savings_seconds

FROM warehouse_metrics;