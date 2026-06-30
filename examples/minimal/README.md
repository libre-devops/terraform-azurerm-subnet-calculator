<!--
  Header for the minimal example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Minimal example

The smallest valid call to this module: required inputs only. The environment comes from the
Terraform workspace (`terraform.workspace`), not a variable. Run it with `just e2e minimal`, which
applies the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_subnet_calculator"></a> [subnet\_calculator](#module\_subnet\_calculator) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cidrs"></a> [cidrs](#output\_cidrs) | The calculated subnet CIDRs, in order. |
| <a name="output_network_subnets"></a> [network\_subnets](#output\_network\_subnets) | Shaped to drop into the network module's subnets input. |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | Full per-subnet facts (cidr, usable IPs, etc.). |
<!-- END_TF_DOCS -->
