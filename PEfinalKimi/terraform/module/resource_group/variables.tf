# terraform/modules/resource_group/variables.tf
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the resource group"
  type        = string
}