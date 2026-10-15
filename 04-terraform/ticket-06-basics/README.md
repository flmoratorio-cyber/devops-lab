# Ticket 06 — Terraform basics: init, plan, apply and forced replacement

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Install Terraform on the control node, download the Docker provider, declare an image and a container, and learn to **read the plan** before applying. Code: [`main.tf`](main.tf) · [`variables.tf`](variables.tf) · [`outputs.tf`](outputs.tf).

## Install (HashiCorp apt repository)
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
terraform -version
```
(Building from source needs a Go toolchain; the package repo is simpler and gets updates.)

## The three HCL blocks
| Block | Role |
|-------|------|
| `terraform { required_providers … }` | Which providers/versions this code needs |
| `provider "docker" { … }` | How to reach the platform (here the local Docker socket; or `host = "…"`) |
| `resource "type" "name" { … }` | The object that will exist (image, container, network…) |

## Workflow
```bash
terraform init        # downloads the provider, writes .terraform.lock.hcl (commit it)
terraform plan        # computes the diff; changes nothing
terraform apply       # executes it (asks for "yes")
```

## Reading the plan: `-/+ … # forces replacement`
Changing the published port (8080 → 8081) and adding an env var produced:

```text
-/+ resource "docker_container" "nginx" {
      ~ env = [ # forces replacement
          + "ENVIRONMENT=training",
        ]
      ~ ports {
          ~ external = 8080 -> 8081 # forces replacement
        }
    }
Plan: 1 to add, 0 to change, 1 to destroy.
```
Docker cannot change env vars or published ports of an existing container. Terraform knows that and plans **destroy → create**. The image resource is untouched because its tag did not change.

On `apply`, the order is `Destroying… → Destruction complete → Creating…`: a ~1 s gap that is irrelevant in a lab, but is **downtime** in production. The `lifecycle { create_before_destroy = true }` meta-argument inverts the order where the platform allows it (here the two containers would fight over the same name/port).

## Errors I hit
| Error | Cause | Fix |
|-------|-------|-----|
| `required` typo (`requiered`) | Misspelled argument in `terraform {}` | HCL is strict; run `terraform validate` |
| `image = docker.image.nginx.image_id` | Wrong reference syntax | References are `<type>.<name>.<attribute>` → `docker_image.nginx.image_id` |
| `Unsupported attribute … private_ip` in an output | The Docker provider has no `private_ip` (that is a cloud-provider idea) | Network info is a nested list: `network_data[0].ip_address` |
| Variable declaration rejected | Spaces / quoting problems in the variable name | Plain identifiers, no spaces |

## Takeaways
- Declarative: describe the end state; Terraform calculates the steps.
- Never mutate infrastructure by hand (`docker stop/exec`) — change the `.tf` and plan.
- Read `plan` for `-/+`, `forces replacement` and the summary line before every apply.
- Parameterize (variables/outputs) from the start: the same code should serve dev and prod.
