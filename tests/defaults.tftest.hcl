# Plan-time tests. This is a pure-computation module (no providers), so no mock or credentials:
#   terraform init -backend=false && terraform test

run "three_of_the_same_size_pack_sequentially" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    subnets = [
      { size = 26 },
      { size = 26 },
      { size = 26 },
    ]
  }

  assert {
    condition     = output.cidrs[0] == "10.0.0.0/26" && output.cidrs[1] == "10.0.0.64/26" && output.cidrs[2] == "10.0.0.128/26"
    error_message = "Three /26s should pack sequentially with no overlap."
  }

  assert {
    condition     = output.subnets["snet-001"].usable_host_count == 59 && output.subnets["snet-001"].first_usable_ip == "10.0.0.4"
    error_message = "Azure-aware facts: a /26 has 64 - 5 = 59 usable hosts and first usable .4."
  }
}

run "mixed_sizes_do_not_overlap" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    subnets = [
      { size = 26 },
      { size = 27 },
    ]
  }

  assert {
    condition     = output.cidrs[0] == "10.0.0.0/26" && output.cidrs[1] == "10.0.0.64/27"
    error_message = "A /26 then a /27 should pack sequentially (the /27 starts where the /26 ends)."
  }
}

run "auto_name_fallback_uses_snet_convention" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    subnets   = [{ size = 26 }]
  }

  assert {
    condition     = contains(keys(output.subnets), "snet-001")
    error_message = "The auto-name fallback should use the snet- convention prefix, not subnet-."
  }
}

run "subnet_name_prefix_is_overridable" {
  command = plan

  variables {
    base_cidr          = "10.0.0.0/24"
    subnet_name_prefix = "sub"
    subnets            = [{ size = 26 }]
  }

  assert {
    condition     = contains(keys(output.subnets), "sub-001")
    error_message = "subnet_name_prefix should override the auto-name prefix."
  }
}

run "convention_naming_from_purpose_and_vnet" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    vnet_name = "vnet-ldo-uks-prd-001"
    subnets = [
      { purpose = "app", size = 26 },
    ]
  }

  assert {
    condition     = contains(keys(output.subnets), "snet-app-vnet-ldo-uks-prd-001")
    error_message = "purpose + vnet_name should produce snet-<purpose>-<vnet_name>."
  }
}

run "netnum_pins_an_explicit_offset" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    subnets = [
      { name = "pinned", size = 26, netnum = 3 },
    ]
  }

  assert {
    condition     = output.subnets["pinned"].cidr == "10.0.0.192/26" && output.subnets["pinned"].pinned == true
    error_message = "A netnum should pin the subnet at that explicit offset (netnum 3 of a /24 into /26 = .192/26)."
  }
}

run "network_subnets_output_is_network_module_shaped" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    subnets   = [{ name = "snet-app", size = 26 }]
  }

  assert {
    condition     = output.network_subnets["snet-app"].address_prefixes[0] == "10.0.0.0/26"
    error_message = "network_subnets should be shaped as { name = { address_prefixes = [cidr] } }."
  }
}

run "ipv6_allocates_cidr_without_host_facts" {
  command = plan

  variables {
    base_cidr = "fd00:0:0:1::/64"
    subnets   = [{ name = "v6", size = 80 }]
  }

  assert {
    condition     = output.subnets["v6"].is_ipv6 == true && output.subnets["v6"].usable_host_count == null && output.subnets["v6"].cidr == "fd00:0:0:1::/80"
    error_message = "IPv6 should allocate a CIDR but not emit IPv4 host facts."
  }
}

run "rejects_size_not_smaller_than_base" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    subnets   = [{ size = 24 }]
  }

  expect_failures = [var.subnets]
}

run "rejects_subnet_smaller_than_azure_minimum" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    subnets   = [{ size = 30 }]
  }

  expect_failures = [var.subnets]
}

run "rejects_subnets_that_do_not_fit" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/26"
    subnets = [
      { size = 27 },
      { size = 27 },
      { size = 27 },
    ]
  }

  expect_failures = [var.subnets]
}
