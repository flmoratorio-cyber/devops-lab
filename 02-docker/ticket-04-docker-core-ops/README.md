# Ticket 04 — Docker core operations & troubleshooting

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Pull an image, run a detached container, publish a port, mount a file from the host and diagnose failures with Docker's own tools. Runnable walkthrough: [`commands.sh`](commands.sh), sample page: [`index.html`](index.html).

## Useful commands

| Command | Purpose |
|---------|---------|
| `docker image ls` / `docker search nginx` | Local images / search the hub (check stars & "official") |
| `docker run -d --name web -p 8080:80 nginx` | Detached, named, host port 8080 → container port 80 |
| `docker ps` / `docker ps -a` | Running only / all, including `Exited` |
| `docker logs <name\|id>` | stdout/stderr of the container — first place to look |
| `docker stop` · `docker rm` · `docker rmi` | Stop · remove container · remove image |

## Problems found and solved

### 1. "name already in use"
A container that exited is **not** deleted. It keeps its name until removed:
`docker ps -a` → `docker rm <name>` → run again.

### 2. `exec: -p: not found` (exit 127)
```bash
docker run --name nginx -d <image> -p 8080:80      # ❌ -p is passed to the container as its command
docker run -p 8080:80 --name nginx -d <image>      # ✅ options first, image last
```
Everything after the image name is the command run *inside* the container. `docker logs` showed it immediately.

### 3. Bind mount: "not a directory"
```text
error mounting "/home/…/index.html" to rootfs at "/usr/share/nginx": … not a directory
```
A bind mount maps 1:1 — **file → file, directory → directory**. Mount the file onto the exact target file (`/usr/share/nginx/html/index.html`) or the directory onto a directory. Also, the source must be an absolute path (`$PWD/index.html`); a bare `index.html` is interpreted as a *named volume*.

### 4. Can't add a mount to a running container
Mounts are fixed at creation. Stop/remove and recreate with `-v` — the first hint of the immutable-container idea that Terraform later enforces ([ticket 06](../../04-terraform/ticket-06-basics)).

### 5. Can't remove an image
Docker refuses to delete an image used by any container (even stopped). Remove the container first, then `docker rmi`.

## Takeaways
- Option order matters: `docker run [options] IMAGE [command]`.
- `docker ps -a` + `docker logs` solve most "it won't start" cases.
- Containers are immutable in practice: change config → recreate.
