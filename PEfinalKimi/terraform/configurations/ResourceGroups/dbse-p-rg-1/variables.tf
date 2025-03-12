variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the resource group"
  type        = string
}

variable "import_existing" {
  description = "Whether to import an existing resource group"
  type        = bool
  default     = false
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "resource_type" {
  description = "Type of the resource"
  type        = string
}

variable "resource_name" {
  description = "Name of the resource"
  type        = string
}

variable "subresource_name" {
  description = "Name of the subresource"
  type        = string
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  type        = string
}

variable "private_dns_zone_resource_group" {
  description = "Resource group of the private DNS zone"
  type        = string
}

variable "static_ips" {
  description = "List of static IP addresses"
  type        = list(string)
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "resource_id" {
  description = "ID of the resource"
  type        = string
}

variable "azure_storage_access_key" {
  description = "Access key for Azure storage account"
  type        = string
  sensitive   = true
}