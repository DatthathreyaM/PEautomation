# terraform/modules/resource_group/main.tf
terraform {
  required_version = "1.3.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

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

resource "azurerm_resource_group" "rg" {
  count = var.import_existing ? 0 : 1

  name     = var.resource_group_name
  location = var.location
}

data "azurerm_resource_group" "existing_rg" {
  count = var.import_existing ? 1 : 0

  name = var.resource_group_name
}

output "resource_group_id" {
  value = var.import_existing ? data.azurerm_resource_group.existing_rg.id : azurerm_resource_group.rg.id
}