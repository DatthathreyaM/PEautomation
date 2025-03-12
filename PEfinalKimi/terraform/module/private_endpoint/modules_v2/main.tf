terraform {
  required_version = ">= 1.3.0"
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

locals {
  dns_zones = {
    "Sql"     = "privatelink.documents.azure.com"
    "Mongodb" = "privatelink.mongo.cosmos.azure.com"
  }
  dns_zone = lookup(local.dns_zones, var.sub_resource_name, null)
}

resource "azurerm_private_endpoint" "example" {
  name                = var.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = var.private_service_connection_name
    private_connection_resource_id = var.resource_id
    subresource_names              = [var.sub_resource_name]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "${var.private_endpoint_name}-ipconfig1"
    private_ip_address = var.static_ips[0]
  }

  ip_configuration {
    name               = "${var.private_endpoint_name}-ipconfig2"
    private_ip_address = var.static_ips[1]
  }
}

resource "azurerm_private_dns_a_record" "example1" {
  name                = "${var.private_endpoint_name}-location"
  zone_name           = local.dns_zone
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.example.ip_configuration[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "example2" {
  name                = var.private_endpoint_name
  zone_name           = local.dns_zone
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.example.ip_configuration[1].private_ip_address]
}