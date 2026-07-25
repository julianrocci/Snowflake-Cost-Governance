STRATEGY :

append :
simply add every new column, no deduplication. Every new row is saved

merge: Default strategy, insert new rows and update rows based on unique_key

delete+insert: delete rows based on unique_key and reinsert with new data, insert new rows.

insert+overwrite: overwrite data per micro partition

microbatch: handle batches based a date, periodically run batches by splitting them by partition. good to handle late arriving data.


None of the strategy handles delete by default, if you need to delete rows ; the best way is to use post hook in your model.


Best optimized model:
If your sources can send you an updated_at field, you can add an ingested_at column in your landing table ->

----------------------
{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'customer_id'
  )
}}

{% if is_incremental() %}
    -- The watermark is based on the latest ingested_at already processed at the landing layer
    {% set query = "SELECT MAX(ingested_at) FROM " ~ this %}
    
    -- Execute the query and retrieve the single value [row 0][col 0]
    {% set last_ingested_at = run_query(query).columns[0][0] %}
{% else %}
    -- Fallback date for the very first run (Full Refresh) when the target table doesn't exist yet
    {% set last_ingested_at = '1970-01-01' %}
{% endif %}

-- MAIN INCREMENTAL MODEL

WITH latest_customer_changes AS (

    SELECT

        customer_id,
        name,
        ingested_at,

        -- Keep the record but maintain the current customer state.
        -- Instead of deleting customers physically, we mark them as inactive.
        CASE
            WHEN _fivetran_deleted = TRUE THEN FALSE
            ELSE TRUE
        END AS is_active,

        -- Optional audit information
        CASE
            WHEN _fivetran_deleted = TRUE 
            THEN CURRENT_TIMESTAMP()
            ELSE NULL
        END AS deleted_at

    FROM {{ ref('landing_customers') }}

    WHERE

        -- This allows late arriving source changes to be captured.
        -- Filter for the incremental delta using our frozen timestamp variable (works for both incremental and full refresh)
        ingested_at > '{{ last_ingested_at }}'

    -- Handles multiples rows by customer_id within the same batch ( takes the most recent row )
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY _fivetran_synced DESC) = 1
)


SELECT *

FROM latest_customer_changes
----------------------
This model process perfectly only the delta and also handles late arriving data perfectly and deletes