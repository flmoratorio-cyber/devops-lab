# Ticket 05 — Automatización de infraestructura con Ansible

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Reemplazar el trabajo manual nodo por nodo del [ticket 03](../../02-docker/ticket-03-docker-install/README.es.md) por código: un inventario en el nodo de control, un playbook que instala Docker en todos los workers y la prueba de **idempotencia**.

## Preparación
```bash
sudo apt update && sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version
```

**Requisito — sudo sin contraseña para el usuario de automatización** (si no, cada play se frena pidiendo contraseña). Usar `visudo`, nunca editar `/etc/sudoers` directo (ver [la recuperación](../../01-linux-networking/troubleshooting-sudoers-grub-recovery/README.es.md)):

```text
<usuario> ALL=(ALL) NOPASSWD:ALL
```

Archivos: [`inventory.example.ini`](inventory.example.ini) · [`playbooks/install_docker.yaml`](playbooks/install_docker.yaml) · [`playbooks/cleanup_docker_repo.yaml`](playbooks/cleanup_docker_repo.yaml)

```bash
ansible-inventory -i inventory.ini --list                 # ¿el inventario se lee bien?
ansible -i inventory.ini servers -m ping                  # conectividad + python
ansible-playbook -i inventory.ini playbooks/install_docker.yaml --syntax-check
ansible-playbook -i inventory.ini playbooks/install_docker.yaml
```

De pasos manuales a módulos:

| Paso manual | Módulo Ansible |
|-------------|----------------|
| `apt remove` / `apt install` | `ansible.builtin.apt` (`state`, `update_cache`) |
| `mkdir -p /etc/apt/keyrings` | `ansible.builtin.file` (`state: directory`) |
| descargar la clave GPG | `ansible.builtin.get_url` |
| escribir el repo | `ansible.builtin.deb822_repository` |
| mantener Docker activo | `ansible.builtin.systemd` |
| `usermod -aG docker` | `ansible.builtin.user` (`groups`, `append`) |

## Troubleshooting: `Failed to update apt cache after 5 retries`
Ansible ocultó el error real detrás de su mensaje de reintentos. Con **comandos ad-hoc** se fue directo a la fuente:

```bash
ansible -i inventory.ini servers -m command -a "apt-get update" --become
ansible -i inventory.ini all -m command -a "grep -rn 'download.docker.com' /etc/apt/" --become
# → /etc/apt/sources.list.d/docker.sources:7: URIs: https://download.docker.com/linux/ubuntu
```
La instalación manual del ticket 03 había dejado un `docker.sources` viejo que era el origen de la falla — al eliminarlo, `apt-get update` funcionó. Solución: [`cleanup_docker_repo.yaml`](playbooks/cleanup_docker_repo.yaml) y luego el playbook de instalación.

## Idempotencia
Ejecutar el playbook dos veces; la segunda debe terminar con `changed=0`.

Qué la rompía al principio: la tarea "borrar archivos de repo viejos" eliminaba justo el archivo que la tarea del repositorio vuelve a crear, así que **cada ejecución reportaba cambios**. La solución fue mover la limpieza a un playbook aparte, de una sola vez.

## Aprendizajes
- Los ad-hoc (`-m command -a …`) son la herramienta de diagnóstico rápido sobre todos los nodos.
- Un play que "repara" e "instala" en el mismo archivo rara vez es idempotente — separarlos.
- Siempre `--syntax-check` y probar primero en un host (`--limit wk1`).
