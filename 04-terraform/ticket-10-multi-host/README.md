# Ticket 10 — Integrator: provider aliases and distributed deployment

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Deploy one Nginx per worker (wk1–wk4) from a single Terraform configuration, each reached over SSH, with a distinct published port per node. Code: [`main.tf`](main.tf) · [`variables.tf`](variables.tf).

## How it works
- One `provider "docker"` block per node, distinguished by `alias`.
- Every resource that must land on a node declares `provider = docker.<alias>` — **both** the image and the container, because each daemon pulls its own image.
- Host and port per node live in variables (`host_wk1…`, `port_wk1…`), not in the resources.

## Why the code repeats per node
It would be natural to loop with `for_each` over a map of nodes, but **a resource's `provider` argument must be static**: provider configurations cannot be chosen dynamically per instance. So the explicit block-per-node pattern (or, in larger setups, a child module called once per provider) is the way to do it.

## Validate (with Ansible, all nodes at once)
```bash
terraform init && terraform plan && terraform apply

ansible -i inventory.ini servers -m command -a "docker ps" --become          # parallel
ansible -i inventory.ini servers -m command -a "docker ps" --become -f 1     # sequential (-f 1 = one fork)

terraform destroy
ansible -i inventory.ini servers -m command -a "docker ps -a" --become       # all empty: clean teardown
```
Result: one container per worker, ports 8081–8084, and a clean slate after `destroy`.

## Takeaways
- A single plan/apply orchestrates four hosts; the state tracks which provider owns what.
- Ansible ad-hoc is the independent auditor of what Terraform claims to have done.
- `destroy` + verification proves the code is the only source of truth.
