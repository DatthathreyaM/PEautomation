# terraform/modules/sql_server/main.tf
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

resource "azurerm_sql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group
  location                     = var.location
  version                      = var.version
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_password

  storage_profile {
    storage_mb           = var.storage_size
    backup_retention_days = 7
    geo_redundant_backup = "Disabled"
  }
}