resource "snowflake_warehouse" "wh_analytics" {
  name                = "WH_ANALYTICS"
  warehouse_size      = "SMALL"

  # Multi-cluster configuration
  min_cluster_count   = 1
  max_cluster_count   = 3
  scaling_policy      = "STANDARD"

  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true

  tags = {
    workload    = "analytics"
    environment = "prod"
    team        = "data"
  }
}

resource "snowflake_warehouse" "wh_batch" {
  name                = "WH_BATCH"
  warehouse_size      = "MEDIUM"

  # Single cluster (controlled ETL workload)
  min_cluster_count   = 1
  max_cluster_count   = 1
  scaling_policy      = "STANDARD"

  auto_suspend        = 300
  auto_resume         = true
  initially_suspended = true

  tags = {
    workload    = "batch"
    environment = "prod"
    team        = "data"
  }
}
