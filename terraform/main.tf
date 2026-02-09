resource "snowflake_warehouse" "analytics_wh" {
  name              = var.warehouse_name
  warehouse_size    = var.warehouse_size
  auto_suspend      = var.auto_suspend_seconds
  auto_resume       = true
  initially_suspended = true

  tags = var.tags
}