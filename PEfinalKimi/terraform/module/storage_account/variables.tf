# terraform/modules/storage_account/variables.tf
variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "resource_group" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the storage account"
  type        = string
}

variable "account_kind" {
  description = "Kind of storage account"
  type        = string
}

variable "account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
}

variable "account_tier" {
  description = "Tier for the storage account"
  type        = string
}

variable "ip_rules" {
  description = "IP rules for the storage account"
  type        = list(string)
}