# Ticket 09 — Terraform against a remote Docker host over SSH

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Until now `provider "docker" {}` used the local socket on `master`. Make `master` create resources on **`wk1`** through the SSH trust that already exists — no Docker TCP port opened. Code: [`main.tf`](main.tf) · [`variables.tf`](variables.tf).

```hcl
provider "docker" {
  host = "ssh://<user>@wk1"
}
```

Requirements on the target: key-based SSH from `master`, Docker installed, the SSH user in the `docker` group.

## Validate
```bash
terraform init && terraform apply
docker ps                    # on master: nothing running
ssh -t wk1 docker ps         # on wk1: the container is there (0.0.0.0:8085->80/tcp)
```

## Starting from a clean slate with Ansible
Leftover containers from earlier tickets would confuse the exercise. Inspect and purge **all nodes at once** with ad-hoc commands:

```bash
ansible -i inventory.ini servers -m command -a "docker ps -a"
ansible -i inventory.ini servers -m command -a "docker system prune -af" --become
```
Adding `ansible_python_interpreter=/usr/bin/python3` under `[servers:vars]` removes the "interpreter discovery" warnings.

## Takeaways
- Terraform and Ansible complement each other: Terraform declares *what exists*, Ansible inspects/configures the hosts.
- SSH as transport = reuse existing authentication instead of exposing `tcp://:2375`.
- The state file knows which host each resource lives on; the provider block decides it.
