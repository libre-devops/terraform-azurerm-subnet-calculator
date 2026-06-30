terraform {
  # Pure-computation module (no providers): it only does CIDR maths with core functions, so it can be
  # called anywhere. Requires 1.9 for cross-variable validation.
  required_version = ">= 1.9.0, < 2.0.0"
}
