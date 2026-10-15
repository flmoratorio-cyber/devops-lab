# Ticket 03 — Docker Engine desde el repositorio oficial

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Instalar Docker Engine como se hace en producción — desde el repositorio apt de Docker, no el paquete `docker.io` de Ubuntu (más viejo y mantenido por otros) — y entender cada componente antes de automatizarlo.

## Pasos
1. **Eliminar paquetes en conflicto** → [`scripts/docker_0_remove_conflicts.sh`](scripts/docker_0_remove_conflicts.sh)
2. **Agregar el repo oficial + clave GPG** → [`scripts/docker_1_repository.sh`](scripts/docker_1_repository.sh)
3. **Instalar** `docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` → [`scripts/docker_2_install.sh`](scripts/docker_2_install.sh)
4. **Usar sin sudo**: `sudo usermod -aG docker <usuario>`
5. **Validar**: `docker run hello-world`

Distribución manual de los scripts, nodo por nodo:

```bash
scp scripts/docker_0_remove_conflicts.sh wk1:/home/<usuario>/
ssh -t wk1 'bash /home/<usuario>/docker_0_remove_conflicts.sh'
```

## Trampa: la pertenencia a un grupo requiere nuevo login
Después de `usermod -aG docker`, `docker run` sigue dando *permission denied* en la sesión actual: los grupos se evalúan al iniciar sesión. Cerrar y volver a entrar, o usar `newgrp docker`.

## Por qué esta es la última instalación manual
Ejecutar los mismos scripts a mano en cuatro workers es lento y propenso a errores — no hay forma de saber que todos quedaron en el mismo estado. Esa fricción es justo el problema que resuelve **Ansible** → [ticket 05](../../03-ansible/ticket-05-ansible-automation/README.es.md).

## Aprendizajes
- Usar el repositorio del fabricante para runtimes de producción; eliminar antes los restos de la distro.
- Pertenecer al grupo docker equivale a root en ese host; otorgarlo con criterio.
