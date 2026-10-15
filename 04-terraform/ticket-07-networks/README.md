# Ticket 07 — Declarative networks and multi-container setup

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Create a private bridge network **with Terraform**, attach two containers to it and prove they talk by name without publishing any port to the host. Code: [`main.tf`](main.tf).

- `docker_network` with explicit addressing (`ipam_config`, `10.10.0.0/24`)
- `web_server`: Nginx on that network
- `test_client`: Alpine on the same network

## Validate
```bash
terraform init && terraform plan && terraform apply
docker exec -it test_client wget -qO- http://web_server     # returns the Nginx page
```
The name resolves because user-defined bridge networks have Docker's embedded DNS (the default `bridge` does not).

## Error: "pull access denied for docker_image.alpine.image_id"
```hcl
image = "docker_image.alpine.image_id"     # ❌ a string literal → Docker tries to pull an image with that name
image = docker_image.alpine.image_id       # ✅ a reference to the resource attribute
```
Quoting a reference turns it into text. Unquoted, Terraform also learns the dependency (image → container) and orders the graph correctly. The same applies to `docker_network.internal.name`.

## Takeaways
- Terraform builds a dependency graph from references; the network and images are created before the containers.
- Internal-only services need no `ports` block — less exposure.
- `docker ps -a` after apply should list exactly the containers declared in code.
