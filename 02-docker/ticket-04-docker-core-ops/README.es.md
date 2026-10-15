# Ticket 04 — Operaciones core de Docker y troubleshooting

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Descargar una imagen, ejecutar un contenedor en segundo plano, publicar un puerto, montar un archivo del host y diagnosticar fallas con las herramientas de Docker. Recorrido ejecutable: [`commands.sh`](commands.sh), página de ejemplo: [`index.html`](index.html).

## Comandos útiles

| Comando | Para qué |
|---------|----------|
| `docker image ls` / `docker search nginx` | Imágenes locales / buscar en el hub (mirar estrellas y "official") |
| `docker run -d --name web -p 8080:80 nginx` | Detached, con nombre, puerto 8080 del host → 80 del contenedor |
| `docker ps` / `docker ps -a` | Solo activos / todos, incluso `Exited` |
| `docker logs <nombre\|id>` | stdout/stderr del contenedor — primer lugar donde mirar |
| `docker stop` · `docker rm` · `docker rmi` | Detener · borrar contenedor · borrar imagen |

## Problemas encontrados y resueltos

### 1. "name already in use"
Un contenedor que terminó **no** se borra. Conserva su nombre hasta eliminarlo:
`docker ps -a` → `docker rm <nombre>` → volver a ejecutar.

### 2. `exec: -p: not found` (exit 127)
```bash
docker run --name nginx -d <imagen> -p 8080:80      # ❌ -p se pasa al contenedor como comando
docker run -p 8080:80 --name nginx -d <imagen>      # ✅ opciones primero, imagen al final
```
Todo lo que va después del nombre de la imagen es el comando que corre *dentro* del contenedor. `docker logs` lo mostró enseguida.

### 3. Bind mount: "not a directory"
```text
error mounting "/home/…/index.html" to rootfs at "/usr/share/nginx": … not a directory
```
Un bind mount mapea 1 a 1 — **archivo → archivo, directorio → directorio**. Montar el archivo sobre el archivo destino exacto (`/usr/share/nginx/html/index.html`) o un directorio sobre un directorio. Además el origen debe ser ruta absoluta (`$PWD/index.html`); un `index.html` suelto se interpreta como *volumen con nombre*.

### 4. No se puede agregar un mount a un contenedor en ejecución
Los mounts se fijan al crear el contenedor. Detener/borrar y recrear con `-v` — primer indicio de la idea de contenedor inmutable que Terraform refuerza después ([ticket 06](../../04-terraform/ticket-06-basics/README.es.md)).

### 5. No se puede borrar una imagen
Docker no elimina una imagen usada por algún contenedor (ni detenido). Borrar primero el contenedor y luego `docker rmi`.

## Aprendizajes
- El orden de las opciones importa: `docker run [opciones] IMAGEN [comando]`.
- `docker ps -a` + `docker logs` resuelven la mayoría de los "no arranca".
- En la práctica los contenedores son inmutables: cambiar config → recrear.
