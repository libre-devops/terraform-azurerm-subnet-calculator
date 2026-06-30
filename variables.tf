variable "base_cidr" {
  description = "Base CIDR to carve subnets from. IPv4 (for example 10.0.0.0/24) or IPv6 (for example fd00:0:0:1::/64)."
  type        = string

  validation {
    condition     = can(cidrhost(var.base_cidr, 0))
    error_message = "base_cidr must be a valid IPv4 or IPv6 CIDR."
  }
}

variable "subnet_name_prefix" {
  description = "Prefix for auto-generated subnet names. Defaults to the Libre DevOps snet- convention; override it, or set an explicit name per subnet, to use your own scheme."
  type        = string
  default     = "snet"
}

variable "subnets" {
  description = <<-EOT
    Ordered list of subnets to carve from base_cidr.

    Allocation is SEQUENTIAL by default (Terraform's cidrsubnets): each subnet without a netnum is
    packed immediately after the previous one, with no overlap, and mixed sizes are handled correctly.
    Give a netnum to PIN a subnet at an explicit offset so it never moves when others change (you are
    then responsible for it not colliding with the sequential range). APPEND-ONLY: adding or removing a
    sequential subnet shifts every sequential subnet after it, so add new ones at the end, or pin the
    ones that must stay put.

    Per entry:
      - size    (required) target prefix length, for example 26. Must be larger than the base prefix.
      - name    (optional) explicit subnet name (wins over purpose).
      - purpose (optional) with vnet_name, builds the convention name snet-<purpose>-<vnet_name>;
                without vnet_name, the purpose is used as the name.
      - netnum  (optional) pin at this offset (cidrsubnet netnum) instead of sequential placement.
  EOT
  type = list(object({
    size    = number
    name    = optional(string)
    purpose = optional(string)
    netnum  = optional(number)
  }))
  default = []

  validation {
    condition     = alltrue([for s in var.subnets : s.size > tonumber(split("/", var.base_cidr)[1])])
    error_message = "Each subnet size (prefix length) must be larger than the base_cidr prefix."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.size <= (strcontains(var.base_cidr, ":") ? 128 : 32)])
    error_message = "Each subnet size must be <= 32 for IPv4 or <= 128 for IPv6."
  }

  validation {
    # Azure reserves 5 addresses per subnet, so the smallest usable IPv4 subnet is /29.
    condition     = strcontains(var.base_cidr, ":") ? true : alltrue([for s in var.subnets : s.size <= 29])
    error_message = "For IPv4, the smallest Azure subnet is /29 (Azure reserves 5 addresses per subnet)."
  }

  validation {
    # The requested subnets must fit in base_cidr (IPv4; IPv6 space is effectively unbounded here).
    condition = (strcontains(var.base_cidr, ":") || length(var.subnets) == 0) ? true : (
      sum([for s in var.subnets : pow(2, 32 - s.size)]) <= pow(2, 32 - tonumber(split("/", var.base_cidr)[1]))
    )
    error_message = "The requested subnets do not all fit within base_cidr."
  }
}

variable "vnet_name" {
  description = "When set, subnets given a purpose (and no explicit name) are named <subnet_name_prefix>-<purpose>-<vnet_name> per the Libre DevOps convention."
  type        = string
  default     = null
}
