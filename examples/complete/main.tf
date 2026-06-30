locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_name = "vnet-${var.short}-${var.loc}-${terraform.workspace}-001"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [
    {
      name     = local.rg_name
      location = local.location
      tags     = module.tags.tags
    },
  ]
}

# The companion: calculate non-overlapping subnets from the vnet's address space, naming them by
# purpose with the snet- convention. The "gw" subnet is pinned with a netnum so it never moves when
# other subnets are added or removed.
module "subnet_calculator" {
  source = "../../"

  base_cidr = "10.30.0.0/24"
  vnet_name = local.vnet_name

  subnets = [
    { purpose = "app", size = 26 },
    { purpose = "data", size = 27 },
    { purpose = "pe", size = 27 },
    { purpose = "gw", size = 27, netnum = 7 },
  ]
}

# Feed the calculated subnets straight into the network module: network_subnets is already shaped as
# { name = { address_prefixes = [cidr] } }.
module "network" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_name
  address_space = [module.subnet_calculator.base_cidr]
  subnets       = module.subnet_calculator.network_subnets
}
