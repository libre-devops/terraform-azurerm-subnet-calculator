output "calculated_subnets" {
  description = "The calculator's per-subnet facts (cidr, usable IPs, etc.)."
  value       = module.subnet_calculator.subnets
}

output "subnet_ids" {
  description = "Map of subnet name to id, as created in Azure."
  value       = module.network.subnet_ids
}

output "tags" {
  description = "The tags applied to the resources."
  value       = module.tags.tags
}

output "vnet_id" {
  description = "The id of the virtual network built from the calculated subnets."
  value       = module.network.vnet_id
}
