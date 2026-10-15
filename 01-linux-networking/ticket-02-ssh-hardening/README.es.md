# Ticket 02 — Hardening de SSH en los workers

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Que la llave SSH sea la **única** forma de entrar a los workers: deshabilitar contraseña y login de root.

## Configuración
Editar `/etc/ssh/sshd_config` (y revisar `/etc/ssh/sshd_config.d/*.conf`, que puede pisarlo):

```text
PasswordAuthentication no
PermitRootLogin no
```

```bash
sudo sshd -t                       # validar sintaxis antes de reiniciar
sudo systemctl restart ssh
```

## Auditoría (prueba de fallo)
Desde `master`, forzar al cliente a ignorar la llave. El servidor debe rechazar de inmediato:

```bash
ssh -o PubkeyAuthentication=no <usuario>@<ip-worker>
# Permission denied (publickey).
```

> **Regla de seguridad:** nunca cerrar la sesión SSH de trabajo mientras se cambia la config de SSH. Probar desde una segunda terminal; si quedás afuera, la primera sigue abierta para revertir.

## Bitácora de troubleshooting
- En Ubuntu el valor efectivo puede estar en un drop-in dentro de `/etc/ssh/sshd_config.d/`, que tiene precedencia sobre el archivo principal (gana la primera coincidencia). En los workers el cambio se hizo en ese drop-in. Ver la config efectiva con `sudo sshd -T | grep -i passwordauthentication`.

## Clonado de workers (wk3, wk4 desde wk2)
Las VMs clonadas heredan la identidad de la original. Checklist por clon:

```bash
sudo hostnamectl set-hostname wk3
passwd                                          # contraseña nueva por nodo
sudo rm /etc/machine-id && sudo systemd-machine-id-setup   # machine-id único
sudo rm /etc/ssh/ssh_host_* && sudo dpkg-reconfigure openssh-server   # host keys nuevas
# actualizar la MAC de la NIC en el hipervisor / netplan y asignar la nueva IP estática
```

Por qué importa el `machine-id`: IDs idénticos en máquinas clonadas hacen que algunos servidores DHCP entreguen la misma concesión y confunden el reenvío de logs centralizado.

## Aprendizajes
- Validar siempre (`sshd -t`) y mantener una segunda sesión abierta.
- Probar el caso *negativo*: un control de seguridad necesita una prueba que falle, no solo una que pase.
