variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_id" {
  type = string
}

variable "private_dns_zone" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "private_endpoint_name" {
  type = string
}

variable "private_service_connection_name" {
  type = string
}

variable "sub_resource_name" {
  type = string
}

variable "ip_configuration_name" {
  type = string
}

variable "static_ips" {
  type = list(string)
}

variable "dns_record_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "resource_group_id" {
  type = string
}