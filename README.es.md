# devops-lab

[🇬🇧 English](README.md) · 🇦🇷 Español

Laboratorio práctico de DevOps / SysOps: un clúster de 5 nodos Ubuntu sobre VMware, construido paso a paso con **tickets** que replican trabajo real de soporte — **Linux y redes → Docker → Ansible → Terraform → Kubernetes**.

Cada ticket documenta el objetivo, los comandos y, sobre todo, **qué falló, por qué y cómo se resolvió**. No es una copia de tutorial: es una bitácora de troubleshooting.

> 📄 La bitácora original del proyecto en una sola página se conserva en [docs/overview.es.md](docs/overview.es.md).

## Topología del laboratorio

| Nodo | Rol | IP host-only (vmnet1) |
|------|-----|-----------------------|
| `master` | Nodo de control (Ansible, Terraform) + futuro control plane de K8s | 192.168.124.10 |
| `wk1` – `wk4` | Workers (Docker, luego K8s) | 192.168.124.101 – .104 |

- VMware Workstation, Ubuntu Server, 4 GB RAM / 2 vCPU por nodo.
- NIC 1: Host-only (gestión y tráfico entre nodos). NIC 2: NAT (internet / actualizaciones).
- Los workers se clonan desde una VM base (hostname, machine-id, host keys e IP se regeneran por clon — ver ticket 02).
- SSH solo con llave desde `master` hacia los workers; `sudo` sin contraseña para el usuario de automatización.

## Roadmap y estado

| # | Ticket | Herramientas | Estado |
|---|--------|--------------|--------|
| 01 | [VMs, IP estática, acceso SSH con llave](01-linux-networking/ticket-01-vm-and-ssh-access/README.es.md) | netplan, ssh-keygen, ssh-copy-id | ✅ |
| 02 | [Hardening de SSH](01-linux-networking/ticket-02-ssh-hardening/README.es.md) | sshd_config | ✅ |
| 02.5 | [DNS local, netcat, cadenas de iptables](01-linux-networking/ticket-02.5-dns-netcat-iptables/README.es.md) | /etc/hosts, nc, iptables | ✅ |
| — | [Recuperación de un sudoers roto](01-linux-networking/troubleshooting-sudoers-grub-recovery/README.es.md) | GRUB, visudo | ✅ |
| 03 | [Docker Engine desde el repo oficial](02-docker/ticket-03-docker-install/README.es.md) | apt, docker | ✅ |
| 04 | [Operaciones core de Docker y troubleshooting](02-docker/ticket-04-docker-core-ops/README.es.md) | docker run/logs/bind mounts | ✅ |
| 05 | [Ansible: inventario, playbooks, idempotencia](03-ansible/ticket-05-ansible-automation/README.es.md) | Ansible | ✅ |
| 06 | [Terraform base: init/plan/apply, reemplazo forzado](04-terraform/ticket-06-basics/README.es.md) | Terraform, provider docker | ✅ |
| 07 | [Redes declarativas](04-terraform/ticket-07-networks/README.es.md) | docker_network | ✅ |
| 08 | [Volúmenes persistentes](04-terraform/ticket-08-volumes/README.es.md) | docker_volume | ✅ |
| 09 | [Host Docker remoto por SSH](04-terraform/ticket-09-remote-host/README.es.md) | provider `host = ssh://` | ✅ |
| 10 | [Despliegue distribuido con alias de provider](04-terraform/ticket-10-multi-host/README.es.md) | multi-provider | ✅ |
| 11 | [Prerrequisitos de Kubernetes + preparación de nodos con Ansible](05-kubernetes/ticket-11-prerequisites/README.es.md) | swap, módulos de kernel, sysctl | ✅ |
| 12 | Creación del clúster (kubeadm, CNI, primeros Deployments/Services) | kubeadm, kubectl | 🔜 en curso |

## Habilidades demostradas

- Administración Linux: usuarios/permisos, netplan, SSH (llaves, hardening, `~/.ssh/config`), sudoers, recuperación por GRUB
- Diagnóstico de red: `ip`, `ss`, `nc`, cadenas de `iptables` (INPUT / OUTPUT / FORWARD)
- Contenedores: Docker Engine, imágenes, mapeo de puertos, bind mounts y volúmenes, lectura de logs
- Gestión de configuración: inventarios, playbooks, comandos ad-hoc e idempotencia en Ansible
- Infraestructura como código: providers, state, semántica de `plan` (`-/+ forces replacement`), variables/outputs, redes, volúmenes, hosts remotos, alias de provider
- Prerrequisitos de Kubernetes: por qué swap off, `overlay` / `br_netfilter`, `ip_forward`, kubeadm vs k3s

## Convenciones

- Cada carpeta de ticket tiene `README.md` (English) y `README.es.md` (Español).
- Hostnames/IPs son solo de laboratorio (rangos privados RFC 1918). **No se versionan credenciales, llaves ni archivos de state** — ver `.gitignore`.
- Terraform: se versiona `.terraform.lock.hcl`, no `*.tfstate`.

## Licencia

MIT
