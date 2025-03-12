# terraform/modules/storage_account/main.tf
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

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  dynamic "network_rules" {
    for_each = var.ip_rules != null ? [1] : []
    content {
      default_action = "Deny"
      ip_rules       = var.ip_rules
    }
  }
}