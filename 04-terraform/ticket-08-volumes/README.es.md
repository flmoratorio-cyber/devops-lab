# Ticket 08 — Persistencia y volúmenes declarativos

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Los contenedores son efímeros: los datos de su capa de escritura mueren con ellos. Desacoplar el ciclo de vida de los datos con un `docker_volume` y **demostrar** que sobreviven a un reemplazo forzado. Código: [`main.tf`](main.tf) · [`variables.tf`](variables.tf).

## Prueba de persistencia
```bash
terraform apply                                              # volumen + contenedor
docker exec nginx-persist sh -c 'echo "persisted" > /usr/share/nginx/html/test.txt'
curl localhost:8085/test.txt                                 # persisted

# cambiar external_port en variables.tf (p. ej. 8085 -> 8086)
terraform plan                                               # -/+ contenedor, volumen intacto
terraform apply
curl localhost:8086/test.txt                                 # sigue devolviendo "persisted"
```
El contenedor se destruyó y se recreó; el volumen — un recurso aparte — no.

## Volumen vs bind mount en `docker_container`
| | Volumen de Docker | Bind mount |
|---|---|---|
| Argumento | `volume_name = docker_volume.web_data.name` | `host_path = "${path.cwd}/site"` |
| Lo administra | Docker (`/var/lib/docker/volumes`) | Vos (una ruta del host) |
| Uso típico | Datos a conservar (BD, uploads) | Código / config que se edita en el host |

## Detalles a tener en cuenta
- `container_path` debe ser **absoluta** (`/usr/share/nginx/html`); sin la barra inicial Docker la rechaza.
- Usar `path.cwd` / `path.module` en vez de rutas fijas `/home/<usuario>/…`.
- `terraform destroy` también borra el volumen, y los datos con él — en la vida real protegerlo (`lifecycle { prevent_destroy = true }`).
