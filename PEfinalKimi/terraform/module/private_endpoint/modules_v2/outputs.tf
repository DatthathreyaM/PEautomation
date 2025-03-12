output "private_endpoint_id" {
  value = azurerm_private_endpoint.pe.id
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_a_record.dns.zone_id
}