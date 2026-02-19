WITH warehouse_base AS (

    SELECT
        warehouse_name,

        /* Core activity metrics */
        SUM(total_elapsed_time) / 1000                           AS total_query_seconds,
        SUM(credits_used_compute)                                 AS total_credits_used,
        SUM(credits_used_cloud_services)                          AS total_cloud_credits,

        /* Time metrics */
        SUM(active_time)                                          AS total_active_query_seconds,
        SUM(billed_time)                                          AS total_billed_seconds

    FROM snowflake.account_usage.warehouse_load_history
    WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    GROUP BY warehouse_name
),

warehouse_ratios AS (

    SELECT
        warehouse_name,

        total_query_seconds,
        total_credits_used,
        total_cloud_credits,
        total_active_query_seconds,
        total_billed_seconds,

        /* Utilization ratios */

        CASE 
            WHEN total_billed_seconds > 0
                THEN total_active_query_seconds / total_billed_seconds
            ELSE 0
        END AS weighted_utilization_ratio,

        CASE
            WHEN total_billed_seconds > 0
                THEN (total_billed_seconds - total_active_query_seconds)
                     / total_billed_seconds
            ELSE 0
        END AS idle_ratio

    FROM warehouse_base
),

utilization_trend AS (

    SELECT
        warehouse_name,

        AVG(CASE 
                WHEN start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
                THEN avg_running
            END) AS avg_util_7d,

        AVG(avg_running) AS avg_util_30d

    FROM snowflake.account_usage.warehouse_load_history
    WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    GROUP BY warehouse_name
),

final_model AS (

    SELECT
        r.warehouse_name,

        r.total_query_seconds,
        r.total_credits_used,
        r.total_cloud_credits,
        r.total_active_query_seconds,
        r.total_billed_seconds,

        r.weighted_utilization_ratio,
        r.idle_ratio,

        t.avg_util_7d,
        t.avg_util_30d,

        /* Utilization trend ratio */
        CASE
            WHEN t.avg_util_30d > 0
                THEN t.avg_util_7d / t.avg_util_30d
            ELSE 1
        END AS utilization_trend_ratio,

        /* Recommendation logic */

        CASE

            WHEN r.weighted_utilization_ratio < 0.30
                THEN 'DOWNSIZE_WAREHOUSE'

            WHEN r.idle_ratio > 0.50
                THEN 'REDUCE_AUTO_SUSPEND_TIMEOUT'

            WHEN r.weighted_utilization_ratio > 0.60
                 AND r.idle_ratio < 0.20
                 AND r.total_billed_seconds > r.total_active_query_seconds * 1.5
                THEN 'REVIEW_MULTI_CLUSTER_CONFIGURATION'

            WHEN t.avg_util_30d > 0
                 AND (t.avg_util_7d / t.avg_util_30d) < 0.85
                THEN 'UTILIZATION_DROP_DETECTED'

            ELSE 'HEALTHY'

        END AS optimization_action,

        /* =============================
           Estimated Waste Calculation
           ============================= */

        CASE

            /* Potential downsizing opportunity */
            WHEN r.weighted_utilization_ratio < 0.30
                THEN r.total_billed_seconds * 0.30

            /* Excessive idle time */
            WHEN r.idle_ratio > 0.50
                THEN r.total_billed_seconds * 0.20

            /* Multi-cluster overprovisioning */
            WHEN r.weighted_utilization_ratio > 0.60
                 AND r.idle_ratio < 0.20
                 AND r.total_billed_seconds > r.total_active_query_seconds * 1.5
                THEN (r.total_billed_seconds - r.total_active_query_seconds)

            ELSE 0

        END AS estimated_waste_seconds,

        /* Waste ratio */
        CASE
            WHEN r.total_billed_seconds > 0
                THEN
                    CASE

                        WHEN r.weighted_utilization_ratio < 0.30
                            THEN 0.30

                        WHEN r.idle_ratio > 0.50
                            THEN 0.20

                        WHEN r.weighted_utilization_ratio > 0.60
                             AND r.idle_ratio < 0.20
                             AND r.total_billed_seconds > r.total_active_query_seconds * 1.5
                            THEN (r.total_billed_seconds - r.total_active_query_seconds)
                                 / r.total_billed_seconds

                        ELSE 0

                    END
            ELSE 0
        END AS estimated_waste_ratio

    FROM warehouse_ratios r
    LEFT JOIN utilization_trend t
        ON r.warehouse_name = t.warehouse_name
)

SELECT *
FROM final_model
ORDER BY estimated_waste_ratio DESC;