# terraform/modules/sql_server/variables.tf
variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "resource_group" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the SQL Server"
  type        = string
}

variable "administrator_login" {
  description = "Administrator login for the SQL Server"
  type        = string
}

variable "administrator_password" {
  description = "Administrator password for the SQL Server"
  type        = string
  sensitive   = true
}

variable "version" {
  description = "Version of the SQL Server"
  type        = string
}

variable "storage_size" {
  description = "Storage size (in GB) for the SQL Server"
  type        = number
}