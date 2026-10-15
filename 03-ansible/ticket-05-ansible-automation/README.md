# Ticket 05 — Infrastructure automation with Ansible

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Replace the manual per-node work of [ticket 03](../../02-docker/ticket-03-docker-install) with code: an inventory on the control node, a playbook that installs Docker on every worker, and proof of **idempotency**.

## Setup
```bash
sudo apt update && sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version
```

**Prerequisite — passwordless sudo for the automation user** (otherwise every play stops at a password prompt). Use `visudo`, never edit `/etc/sudoers` directly (see [the recovery write-up](../../01-linux-networking/troubleshooting-sudoers-grub-recovery)):

```text
<user> ALL=(ALL) NOPASSWD:ALL
```

Files: [`inventory.example.ini`](inventory.example.ini) · [`playbooks/install_docker.yaml`](playbooks/install_docker.yaml) · [`playbooks/cleanup_docker_repo.yaml`](playbooks/cleanup_docker_repo.yaml)

```bash
ansible-inventory -i inventory.ini --list                 # inventory parsed correctly?
ansible -i inventory.ini servers -m ping                  # connectivity + python
ansible-playbook -i inventory.ini playbooks/install_docker.yaml --syntax-check
ansible-playbook -i inventory.ini playbooks/install_docker.yaml
```

Module mapping from the manual steps:

| Manual step | Ansible module |
|-------------|----------------|
| `apt remove` / `apt install` | `ansible.builtin.apt` (`state`, `update_cache`) |
| `mkdir -p /etc/apt/keyrings` | `ansible.builtin.file` (`state: directory`) |
| download GPG key | `ansible.builtin.get_url` |
| write the repo | `ansible.builtin.deb822_repository` |
| keep Docker running | `ansible.builtin.systemd` |
| `usermod -aG docker` | `ansible.builtin.user` (`groups`, `append`) |

## Troubleshooting: `Failed to update apt cache after 5 retries`
Ansible hid the real error behind its retry message. Going to the source with **ad-hoc commands** found it:

```bash
ansible -i inventory.ini servers -m command -a "apt-get update" --become
ansible -i inventory.ini all -m command -a "grep -rn 'download.docker.com' /etc/apt/" --become
# → /etc/apt/sources.list.d/docker.sources:7: URIs: https://download.docker.com/linux/ubuntu
```
The manual install of ticket 03 had left a stale `docker.sources` file that was the source of the failure — once removed, `apt-get update` succeeded. Fix: [`cleanup_docker_repo.yaml`](playbooks/cleanup_docker_repo.yaml), then the install playbook.

## Idempotency
Run the playbook twice; the second run must end with `changed=0`.

What broke it initially: the playbook's "remove stale repo files" task deleted the very file that the repository task recreates, so **every run reported changes**. The fix was to move the cleanup to its own one-off playbook.

## Takeaways
- Ad-hoc commands (`-m command -a …`) are the fast diagnostic tool across all nodes.
- A play that "fixes" and "installs" in the same file is rarely idempotent — separate them.
- Always `--syntax-check` and run on one host (`--limit wk1`) first.
