# devops-lab

🇬🇧 English · [🇦🇷 Español](README.es.md)

Hands-on DevOps / SysOps home lab: a 5-node Ubuntu cluster on VMware, built step by step through **tickets** that mirror real support work — **Linux & networking → Docker → Ansible → Terraform → Kubernetes**.

Every ticket documents the objective, the commands, **what broke, why, and how it was fixed**. The goal is not a tutorial copy: it is a troubleshooting log.

> 📄 The original single-page project log (Spanish) is preserved in [docs/overview.es.md](docs/overview.es.md).

## Lab topology

| Node | Role | Host-only IP (vmnet1) |
|------|------|-----------------------|
| `master` | Control node (Ansible, Terraform) + future K8s control plane | 192.168.124.10 |
| `wk1` – `wk4` | Workers (Docker, later K8s) | 192.168.124.101 – .104 |

- VMware Workstation, Ubuntu Server, 4 GB RAM / 2 vCPU per node.
- NIC 1: Host-only (management, inter-node traffic). NIC 2: NAT (internet / updates).
- Workers are cloned from a base VM (hostname, machine-id, host keys and IP are regenerated per clone — see ticket 02).
- Key-only SSH from `master` to all workers; passwordless `sudo` for the automation user.

## Roadmap & status

| # | Ticket | Tools | Status |
|---|--------|-------|--------|
| 01 | [VMs, static IPs, SSH key access](01-linux-networking/ticket-01-vm-and-ssh-access) | netplan, ssh-keygen, ssh-copy-id | ✅ |
| 02 | [SSH hardening](01-linux-networking/ticket-02-ssh-hardening) | sshd_config | ✅ |
| 02.5 | [Local DNS, netcat, iptables chains](01-linux-networking/ticket-02.5-dns-netcat-iptables) | /etc/hosts, nc, iptables | ✅ |
| — | [Recovering from a broken sudoers file](01-linux-networking/troubleshooting-sudoers-grub-recovery) | GRUB, visudo | ✅ |
| 03 | [Docker Engine from the official repo](02-docker/ticket-03-docker-install) | apt, docker | ✅ |
| 04 | [Docker core operations & troubleshooting](02-docker/ticket-04-docker-core-ops) | docker run/logs/bind mounts | ✅ |
| 05 | [Ansible: inventory, playbooks, idempotency](03-ansible/ticket-05-ansible-automation) | Ansible | ✅ |
| 06 | [Terraform basics: init/plan/apply, forced replacement](04-terraform/ticket-06-basics) | Terraform, docker provider | ✅ |
| 07 | [Declarative networks](04-terraform/ticket-07-networks) | docker_network | ✅ |
| 08 | [Persistent volumes](04-terraform/ticket-08-volumes) | docker_volume | ✅ |
| 09 | [Remote Docker host over SSH](04-terraform/ticket-09-remote-host) | provider `host = ssh://` | ✅ |
| 10 | [Distributed deploy with provider aliases](04-terraform/ticket-10-multi-host) | multi-provider | ✅ |
| 11 | [Kubernetes prerequisites + node prep with Ansible](05-kubernetes/ticket-11-prerequisites) | swap, kernel modules, sysctl | ✅ |
| 12 | Cluster bootstrap (kubeadm, CNI, first Deployments/Services) | kubeadm, kubectl | 🔜 in progress |

## Skills demonstrated

- Linux administration: users/permissions, netplan, SSH (keys, hardening, `~/.ssh/config`), sudoers, GRUB recovery
- Networking diagnostics: `ip`, `ss`, `nc`, `iptables` chains (INPUT / OUTPUT / FORWARD)
- Containers: Docker Engine, images, port mapping, bind mounts and volumes, reading container logs
- Configuration management: Ansible inventories, playbooks, ad-hoc commands, idempotency
- Infrastructure as Code: Terraform providers, state, plan semantics (`-/+ forces replacement`), variables/outputs, networks, volumes, remote hosts, provider aliases
- Kubernetes prerequisites: why swap off, `overlay` / `br_netfilter`, `ip_forward`, kubeadm vs k3s

## Conventions

- Each ticket folder has `README.md` (English) and `README.es.md` (Español).
- Hostnames/IPs are lab-only (private RFC 1918 ranges). **No credentials, keys or state files are committed** — see `.gitignore`.
- Terraform: `.terraform.lock.hcl` is committed, `*.tfstate` is not.

## License

MIT
