# Ticket 06 — Terraform base: init, plan, apply y reemplazo forzado

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Instalar Terraform en el nodo de control, descargar el provider de Docker, declarar una imagen y un contenedor y aprender a **leer el plan** antes de aplicar. Código: [`main.tf`](main.tf) · [`variables.tf`](variables.tf) · [`outputs.tf`](outputs.tf).

## Instalación (repositorio apt de HashiCorp)
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
terraform -version
```
(Compilar desde el código fuente requiere Go; el repositorio de paquetes es más simple y recibe actualizaciones.)

## Los tres bloques de HCL
| Bloque | Rol |
|--------|-----|
| `terraform { required_providers … }` | Qué providers/versiones necesita el código |
| `provider "docker" { … }` | Cómo llegar a la plataforma (acá el socket local de Docker; o `host = "…"`) |
| `resource "tipo" "nombre" { … }` | El objeto que va a existir (imagen, contenedor, red…) |

## Flujo de trabajo
```bash
terraform init        # descarga el provider, crea .terraform.lock.hcl (versionarlo)
terraform plan        # calcula la diferencia; no cambia nada
terraform apply       # la ejecuta (pide "yes")
```

## Leer el plan: `-/+ … # forces replacement`
Al cambiar el puerto publicado (8080 → 8081) y agregar una variable de entorno apareció:

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
Docker no permite cambiar variables de entorno ni puertos publicados de un contenedor existente. Terraform lo sabe y planifica **destruir → crear**. El recurso de la imagen no se toca porque su tag no cambió.

En el `apply` el orden es `Destroying… → Destruction complete → Creating…`: ~1 s de diferencia que en un laboratorio no importa, pero en producción es **downtime**. El meta-argumento `lifecycle { create_before_destroy = true }` invierte el orden cuando la plataforma lo permite (acá los dos contenedores pelearían por el mismo nombre/puerto).

## Errores que aparecieron
| Error | Causa | Solución |
|-------|-------|----------|
| Typo `requiered` en lugar de `required` | Argumento mal escrito en `terraform {}` | HCL es estricto; usar `terraform validate` |
| `image = docker.image.nginx.image_id` | Sintaxis de referencia incorrecta | Las referencias son `<tipo>.<nombre>.<atributo>` → `docker_image.nginx.image_id` |
| `Unsupported attribute … private_ip` en un output | El provider de Docker no tiene `private_ip` (eso es de proveedores cloud) | La info de red es una lista anidada: `network_data[0].ip_address` |
| Declaración de variable rechazada | Espacios / comillas en el nombre | Identificadores simples, sin espacios |

## Aprendizajes
- Declarativo: se describe el estado final; Terraform calcula los pasos.
- Nunca modificar la infraestructura a mano (`docker stop/exec`) — cambiar el `.tf` y hacer plan.
- Leer en cada `plan`: `-/+`, `forces replacement` y la línea de resumen antes de aplicar.
- Parametrizar (variables/outputs) desde el principio: el mismo código debe servir para dev y prod.
