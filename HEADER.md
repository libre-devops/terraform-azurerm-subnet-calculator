<!--
  This is the template for every Libre DevOps Terraform module. When you create a module from it:
    - replace the title, tagline, and the CI workflow / repo name in the badge URLs
    - replace the resources in main.tf, and the variables, outputs, and examples to match
    - run `just docs` (or Sort-LdoTerraform.ps1) to regenerate the section between the markers
-->
<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Subnet Calculator

Calculates non-overlapping Azure subnet CIDRs from a base address space, the companion to the network
module. Pure computation, no resources.

[![CI](https://github.com/libre-devops/terraform-azurerm-subnet-calculator/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-subnet-calculator/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-subnet-calculator?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-subnet-calculator/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-subnet-calculator)](./LICENSE)

---

## Overview

Give it a base CIDR and a list of subnet sizes and it carves them out **sequentially and
non-overlapping** (via `cidrsubnets`, so mixed sizes are handled correctly), names them with your
`snet-` convention, and emits an output shaped to drop **straight into the network module**. IPv4 and
IPv6.

- **Quick:** "give me three /26s", sizes only, auto-named `snet-001..` (prefix overridable via
  `subnet_name_prefix`).
- **Convention names:** give a `purpose` (+ `vnet_name`) and get `snet-<purpose>-<vnet_name>`.
- **Pin what must not move:** set a `netnum` to fix a subnet at an explicit offset; everything else
  stays sequential. Sequential allocation is **append-only** (inserting shifts later subnets), so pin
  the stable ones.
- **Azure-aware facts:** usable host count and first-usable IP account for Azure's 5 reserved
  addresses per subnet (smallest IPv4 subnet is `/29`).

## Usage

```hcl
module "subnet_calculator" {
  source  = "libre-devops/subnet-calculator/azurerm"
  version = "~> 4.0"

  base_cidr = "10.0.0.0/24"
  vnet_name = "vnet-ldo-uks-prd-001"

  subnets = [
    { purpose = "app", size = 26 },
    { purpose = "data", size = 27 },
    { purpose = "gw", size = 27, netnum = 7 }, # pinned, never moves
  ]
}

module "network" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  vnet_name     = "vnet-ldo-uks-prd-001"
  address_space = [module.subnet_calculator.base_cidr]
  subnets       = module.subnet_calculator.network_subnets
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - "give me three /26s" (pure calculation).
- [`examples/complete`](./examples/complete) - the companion flow: calculate subnets, then build the
  vnet and subnets from them with the network module.

## Developing

This repo is the template every Libre DevOps Terraform module is generated from: clone it, swap in
your resources, and you inherit the standard layout, examples, tests, CI, and release tooling. Local
work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.
