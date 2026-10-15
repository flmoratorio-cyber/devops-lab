# Ticket 08 — Persistence and declarative volumes

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Containers are ephemeral: data in the writable layer dies with the container. Decouple the data lifecycle with a `docker_volume` and **prove** it survives a forced replacement. Code: [`main.tf`](main.tf) · [`variables.tf`](variables.tf).

## Persistence test
```bash
terraform apply                                              # volume + container
docker exec nginx-persist sh -c 'echo "persisted" > /usr/share/nginx/html/test.txt'
curl localhost:8085/test.txt                                 # persisted

# change external_port in variables.tf (e.g. 8085 -> 8086)
terraform plan                                               # -/+ container, volume untouched
terraform apply
curl localhost:8086/test.txt                                 # still "persisted"
```
The container was destroyed and recreated; the volume — a separate resource — was not.

## Volume vs bind mount in `docker_container`
| | Docker volume | Bind mount |
|---|---|---|
| Argument | `volume_name = docker_volume.web_data.name` | `host_path = "${path.cwd}/site"` |
| Managed by | Docker (`/var/lib/docker/volumes`) | You (a path on the host) |
| Typical use | Data to keep (DBs, uploads) | Source code / config edited on the host |

## Gotchas
- `container_path` must be **absolute** (`/usr/share/nginx/html`); without the leading slash Docker rejects it.
- Use `path.cwd` / `path.module` instead of hard-coded `/home/<user>/…` paths.
- `terraform destroy` removes the volume too, and the data with it — in real life protect it (`lifecycle { prevent_destroy = true }`).
