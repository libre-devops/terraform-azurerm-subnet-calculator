output "base_cidr" {
  description = "The base CIDR the subnets were carved from."
  value       = var.base_cidr
}

output "cidrs" {
  description = "Calculated subnet CIDRs in the order the subnets were requested."
  value       = [for i, s in local.resolved : local.cidr_by_index[i]]
}

output "cidrs_map" {
  description = "Map of subnet name to its calculated CIDR."
  value       = { for name, s in local.subnets : name => s.cidr }
}

output "network_subnets" {
  description = "Map of subnet name to { address_prefixes = [cidr] }, shaped to drop straight into the terraform-azurerm-network module's subnets input (merge in your per-subnet settings)."
  value       = { for name, s in local.subnets : name => { address_prefixes = [s.cidr] } }
}

output "subnet_cidrs_zipmap" {
  description = "Map of subnet name to a { name, cidr } object, for handing the whole object downstream."
  value       = { for name, s in local.subnets : name => { name = s.name, cidr = s.cidr } }
}

output "subnets" {
  description = "Map of subnet name to its full facts: cidr, prefix_length, is_ipv6, pinned, netmask, network_address, first_usable_ip, last_usable_ip, usable_host_count (host facts are IPv4-only; null for IPv6)."
  value       = local.subnets
}
