# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They are the place to enforce module-wide consistency.

# Two subnets resolving to the same name silently collapse in the keyed map, so fewer subnets come
# out than were requested.
check "no_duplicate_subnet_names" {
  assert {
    condition     = length(local.subnets) == length(var.subnets)
    error_message = "Two subnets resolved to the same name; each name (or purpose + vnet_name) must be unique."
  }
}
