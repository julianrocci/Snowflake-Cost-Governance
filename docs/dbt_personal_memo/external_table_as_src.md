To handle external table as source define them into your sources.yml then use pre-hook method to ask snowflake to refresh 



------
{{
    config(
        materialized='incremental',
        unique_key='event_id',
        incremental_strategy='delete+insert',
        pre_hook=[
            "ALTER EXTERNAL TABLE {{ source('crm_events', 'ext_customer_events').render() }} REFRESH"
        ]
    )
}}

...........
from {{ source('crm_events', 'ext_customer_events') }}
...........
------

Use .render() to avoid compilation problems when running command using --empty or --sample flag