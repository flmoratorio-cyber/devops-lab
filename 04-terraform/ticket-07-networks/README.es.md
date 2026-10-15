# Ticket 07 — Redes declarativas y multicontenedor

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Crear una red bridge privada **con Terraform**, conectar dos contenedores y comprobar que se comunican por nombre sin publicar ningún puerto al host. Código: [`main.tf`](main.tf).

- `docker_network` con direccionamiento explícito (`ipam_config`, `10.10.0.0/24`)
- `web_server`: Nginx en esa red
- `test_client`: Alpine en la misma red

## Validación
```bash
terraform init && terraform plan && terraform apply
docker exec -it test_client wget -qO- http://web_server     # devuelve la página de Nginx
```
El nombre resuelve porque las redes bridge definidas por el usuario tienen el DNS embebido de Docker (la `bridge` por defecto no).

## Error: "pull access denied for docker_image.alpine.image_id"
```hcl
image = "docker_image.alpine.image_id"     # ❌ texto literal → Docker intenta descargar una imagen con ese nombre
image = docker_image.alpine.image_id       # ✅ referencia al atributo del recurso
```
Poner comillas a una referencia la convierte en texto. Sin comillas, Terraform además detecta la dependencia (imagen → contenedor) y ordena el grafo. Lo mismo vale para `docker_network.internal.name`.

## Aprendizajes
- Terraform arma un grafo de dependencias a partir de las referencias; la red y las imágenes se crean antes que los contenedores.
- Un servicio solo interno no necesita bloque `ports` — menos exposición.
- `docker ps -a` después del apply debe listar exactamente los contenedores declarados en el código.
