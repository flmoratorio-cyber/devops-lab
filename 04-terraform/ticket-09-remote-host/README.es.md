# Ticket 09 — Terraform sobre un host Docker remoto por SSH

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Hasta ahora `provider "docker" {}` usaba el socket local de `master`. Hacer que `master` cree recursos en **`wk1`** usando la confianza SSH que ya existe — sin abrir ningún puerto TCP de Docker. Código: [`main.tf`](main.tf) · [`variables.tf`](variables.tf).

```hcl
provider "docker" {
  host = "ssh://<usuario>@wk1"
}
```

Requisitos en el destino: SSH con llave desde `master`, Docker instalado y el usuario SSH en el grupo `docker`.

## Validación
```bash
terraform init && terraform apply
docker ps                    # en master: nada corriendo
ssh -t wk1 docker ps         # en wk1: el contenedor está ahí (0.0.0.0:8085->80/tcp)
```

## Partir de cero con Ansible
Contenedores sobrantes de tickets anteriores confundirían el ejercicio. Inspeccionar y limpiar **todos los nodos a la vez** con ad-hoc:

```bash
ansible -i inventory.ini servers -m command -a "docker ps -a"
ansible -i inventory.ini servers -m command -a "docker system prune -af" --become
```
Agregar `ansible_python_interpreter=/usr/bin/python3` en `[servers:vars]` elimina los avisos de "interpreter discovery".

## Aprendizajes
- Terraform y Ansible se complementan: Terraform declara *qué existe*, Ansible inspecciona/configura los hosts.
- SSH como transporte = reutilizar la autenticación existente en vez de exponer `tcp://:2375`.
- El state sabe en qué host vive cada recurso; lo decide el bloque provider.
