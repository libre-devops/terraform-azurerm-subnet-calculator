output "cidrs" {
  description = "The calculated subnet CIDRs, in order."
  value       = module.subnet_calculator.cidrs
}

output "network_subnets" {
  description = "Shaped to drop into the network module's subnets input."
  value       = module.subnet_calculator.network_subnets
}

output "subnets" {
  description = "Full per-subnet facts (cidr, usable IPs, etc.)."
  value       = module.subnet_calculator.subnets
}
