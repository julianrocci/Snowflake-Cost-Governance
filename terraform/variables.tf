variable "snowflake_account" {}
variable "snowflake_user" {}
variable "snowflake_role" {
  default = "SYSADMIN"
}

variable "warehouse_name" {
  default = "WH_ANALYTICS"
}

variable "warehouse_size" {
  default = "SMALL"
}

variable "auto_suspend_seconds" {
  default = 60
}

variable "tags" {
  type = map(string)
  default = {
    workload     = "analytics"
    environment  = "prod"
    team         = "data"
  }
}