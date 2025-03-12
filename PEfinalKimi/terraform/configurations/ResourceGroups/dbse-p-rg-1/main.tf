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

# Resource group module
module "resource_group" {
  source = "../../../../../terraform/modules/resource_group"

  resource_group_name = var.resource_group_name
  location            = var.location
  import_existing     = var.import_existing
}

# Private endpoint module
module "private_endpoint" {
  source = "../../../../../terraform/modules/private_endpoint/module_v1"

  resource_group      = module.resource_group.resource_group_id
  location            = module.resource_group.location
  vnet_name           = var.vnet_name
  subnet_name         = var.subnet_name
  resource_type       = var.resource_type
  resource_name       = var.resource_name
  subresource_name    = var.subresource_name
  private_dns_zone_name = var.private_dns_zone_name
  private_dns_zone_resource_group = var.private_dns_zone_resource_group
  static_ips          = var.static_ips
  subnet_id           = var.subnet_id
  resource_id         = var.resource_id
  azure_storage_access_key = var.azure_storage_access_key
}