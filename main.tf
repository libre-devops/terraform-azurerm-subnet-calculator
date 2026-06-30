# Pure CIDR maths, no resources. Non-pinned subnets are packed sequentially with cidrsubnets (correct
# for mixed sizes, never overlapping); pinned subnets (netnum set) are placed at an explicit offset
# with cidrsubnet. Azure-aware facts assume Azure reserves 5 addresses per subnet (first usable is the
# 5th address, smallest IPv4 subnet is /29).
locals {
  is_ipv6        = strcontains(var.base_cidr, ":")
  base_mask      = tonumber(split("/", var.base_cidr)[1])
  azure_reserved = 5

  # Resolve a name and the cidrsubnets "newbits" for each requested subnet, preserving order.
  resolved = [for i, s in var.subnets : {
    name = (
      s.name != null ? s.name :
      (s.purpose != null && var.vnet_name != null) ? "${var.subnet_name_prefix}-${s.purpose}-${var.vnet_name}" :
      s.purpose != null ? "${var.subnet_name_prefix}-${s.purpose}" :
      format("%s-%03d", var.subnet_name_prefix, i + 1)
    )
    size    = s.size
    netnum  = s.netnum
    newbits = s.size - local.base_mask
  }]

  # Sequential allocation over the non-pinned subnets, in list order.
  nonpinned_indices = [for i, s in local.resolved : i if s.netnum == null]
  nonpinned_newbits = [for s in local.resolved : s.newbits if s.netnum == null]
  nonpinned_cidrs   = length(local.nonpinned_newbits) > 0 ? cidrsubnets(var.base_cidr, local.nonpinned_newbits...) : []

  # CIDR per original index: sequential ones zipped back by position, pinned ones placed directly.
  cidr_by_index = merge(
    { for pos, idx in local.nonpinned_indices : idx => local.nonpinned_cidrs[pos] },
    { for i, s in local.resolved : i => cidrsubnet(var.base_cidr, s.newbits, s.netnum) if s.netnum != null },
  )

  # Rich, Azure-aware facts per subnet (host maths IPv4-only; IPv6 host counts are not meaningful).
  subnets = { for i, s in local.resolved : s.name => merge(
    {
      name          = s.name
      cidr          = local.cidr_by_index[i]
      prefix_length = s.size
      is_ipv6       = local.is_ipv6
      pinned        = s.netnum != null
    },
    local.is_ipv6 ? {
      netmask           = null
      network_address   = cidrhost(local.cidr_by_index[i], 0)
      first_usable_ip   = cidrhost(local.cidr_by_index[i], 1)
      last_usable_ip    = null
      usable_host_count = null
      } : {
      netmask           = cidrnetmask(local.cidr_by_index[i])
      network_address   = cidrhost(local.cidr_by_index[i], 0)
      first_usable_ip   = cidrhost(local.cidr_by_index[i], local.azure_reserved - 1)
      last_usable_ip    = cidrhost(local.cidr_by_index[i], pow(2, 32 - s.size) - 2)
      usable_host_count = pow(2, 32 - s.size) - local.azure_reserved
    }
  ) }
}
