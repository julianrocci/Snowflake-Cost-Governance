Snowflake Cost Attribution & Inefficiency Model
1. Purpose of the Cost Model

The purpose of this cost model is to provide a transparent, explainable, and governance-oriented approach to Snowflake cost attribution.

Snowflake costs are inherently warehouse-based and shared across multiple users and workloads. As a result, this model focuses on reasonable estimations rather than attempting exact per-query or per-user billing.

The goal is to support cost visibility, accountability, and optimization decisions, not financial precision.

2. Fundamental Assumptions

This model is built on the following core assumptions:

Snowflake compute costs are generated exclusively by warehouse usage
Warehouses are billed based on active runtime, regardless of individual query concurrency
Costs are shared across all queries running on a warehouse
Cost attribution is an estimation process and depends on documented assumptions
These assumptions are explicitly stated to ensure transparency and auditability.

3. Sources of Truth
3.1 Warehouse Metering (Ground Truth)

The primary source of cost information is:
SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY

This view provides:
billed warehouse runtime
credits consumed
per warehouse and per time window

All cost calculations originate from this data. No cost is created or inferred outside of this source.

3.2 Query Activity Metadata

Query-level metadata is extracted from:
SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY

This data is used to:
understand warehouse usage patterns
distribute warehouse cost across users, teams, and workloads
analyze inefficiencies and optimization opportunities

Query metadata is never treated as a direct cost source.

4. Cost Layers

The model separates cost into three conceptual layers.

4.1 Total Warehouse Cost

Total cost is calculated per warehouse and per period directly from warehouse metering data.
This represents the total amount billed by Snowflake for compute resources.

4.2 Active vs Idle Cost

Total warehouse cost is split into:

Active Cost: cost incurred while executing queries
Idle Cost: cost incurred while the warehouse is running without executing queries

Idle cost is explicitly calculated and never implicitly merged into active usage.

4.3 Attribution Dimensions

Active and idle costs can be analyzed across the following dimensions:
Warehouse
Team
Environment
Workload
User or role (when relevant)

These dimensions are used for analytical and governance purposes.

5. Cost Attribution Rules
5.1 Warehouse-First Attribution

All costs are attributed starting from the warehouse level.
No user, role, or query-level cost attribution is performed without first determining the warehouse-level cost.

5.2 Active Cost Allocation

Active cost is allocated proportionally based on query execution time within each warehouse.

Conceptually:
Entity cost share = Entity query execution time / Total execution time on warehouse

This approach provides a reasonable and explainable approximation of relative usage.

5.3 Idle Cost Handling

Idle cost is treated as a separate cost category and is allocated based on governance rules rather than query activity.

Supported strategies include:
Warehouse owner–based allocation
Proportional allocation based on active usage
Even distribution across consuming teams

Idle cost attribution rules are configurable and explicitly documented.

5.4 Tag-Based Enrichment

Tags are used to enrich cost attribution with business context.

Tag priority is defined as follows:
Warehouse-level tags
Query-level tags
User-level tags (fallback)

Tags do not generate cost, they provide attribution dimensions.

6. Special Cases
6.1 Cached Queries

Queries served from the Snowflake result cache do not contribute to warehouse compute consumption.

These queries are:
excluded from active cost allocation
analyzed separately for usage pattern insights

6.2 Parallel Query Execution

Parallel query execution does not imply a linear increase in warehouse cost.

As Snowflake costs are shared at the warehouse level, parallel queries are treated proportionally based on execution time without attempting fine-grained causal attribution.

7. Inefficiency Detection

The model includes analytical patterns to identify cost inefficiencies.

7.1 High Idle Ratio

Warehouses with a high proportion of idle cost relative to total cost are flagged for investigation.

7.2 Frequent Short-Running Queries

Short-running queries executed frequently may cause excessive warehouse wake-ups and idle cost.

This pattern often indicates suboptimal scheduling or workload design.

7.3 Poor Workload Isolation

Warehouses running workloads (BI and ETL) with high concurrency may suffer from performance degradation and inefficient cost sharing.

7.4 Over-Provisioned Warehouses

Warehouses with consistently low utilization relative to their size are identified as potential candidates for resizing.

8. Limitations and Transparency

This model intentionally avoids claiming precise per-query or per-user cost accuracy.

Key limitations include:
shared warehouse billing
concurrency effects
cached query behavior
idle cost attribution

All assumptions and limitations are documented to ensure transparency and trust in the model outputs.

9. Intended Outcomes

This cost model is designed to support:
cost visibility and accountability
data-driven optimization decisions
governance discussions between data, platform, and finance teams
continuous improvement of Snowflake usage patterns

Summary :

This cost attribution model prioritizes explainability, governance, and decision support over false precision. It reflects real-world Snowflake usage constraints and provides a solid foundation for enterprise-grade cost management.