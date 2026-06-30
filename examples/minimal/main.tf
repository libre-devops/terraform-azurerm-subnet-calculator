# Minimal: "give me three /26s" out of a /24. Pure calculation, no Azure resources, sequential and
# non-overlapping.
module "subnet_calculator" {
  source = "../../"

  base_cidr = "10.0.0.0/24"

  subnets = [
    { size = 26 },
    { size = 26 },
    { size = 26 },
  ]
}
