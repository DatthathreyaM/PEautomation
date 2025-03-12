# terraform/modules/private_endpoint/module_v1/main.tf
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

resource "azurerm_private_endpoint" "pe" {
  name                = "${var.resource_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.resource_name}-psc"
    private_connection_resource_id = var.resource_id
    is_manual_connection           = false
    subresource_names              = [var.subresource_name]
  }

  ip_configuration {
    name      = "ipconfig1"
    private_ip_address = var.static_ips[0]
  }
}

resource "azurerm_private_dns_a_record" "dns" {
  name                = var.resource_name
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe.private_ip_address]
}