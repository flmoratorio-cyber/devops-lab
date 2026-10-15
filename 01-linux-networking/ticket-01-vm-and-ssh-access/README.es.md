# Ticket 01 — VMs, IP estática y SSH con llave

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Dejar lista la base del laboratorio: VMs Ubuntu Server que se vean entre sí y salgan a internet, con SSH sin contraseña desde el nodo de control (`master`) hacia cada worker. Ansible y Terraform dependen de esto más adelante.

## Qué se hizo
1. Se crearon las VMs (Ubuntu Server) sobre una red host-only (`vmnet1`, `192.168.124.0/24`).
2. IP estática con netplan (`/etc/netplan/*.yaml`, luego `sudo netplan apply`).
3. Verificación de conectividad L2/L3 entre nodos.
4. Chequeo del servidor SSH: `systemctl status ssh` y `ss -tuln | grep :22`.
5. Generación del par de llaves en `master` y copia de la pública a cada worker.

```bash
# en master
ssh-keygen -t ed25519 -f ~/.ssh/lab_master
ssh-copy-id -i ~/.ssh/lab_master.pub <usuario>@192.168.124.101
ssh -i ~/.ssh/lab_master <usuario>@192.168.124.101      # primera prueba
```

Ejemplo de IP estática (`/etc/netplan/50-lab.yaml`):

```yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses: [192.168.124.10/24]
```

## Bitácora de troubleshooting

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `master` ↔ workers sin respuesta, pero los workers sí se ven entre sí | Master y workers estaban en segmentos IP distintos | Poner todos los nodos en la misma subred |
| `ssh`: red inaccesible | Error de tipeo en la IP del worker | Verificar con `ip a show <iface>` en el destino y reescribir |
| `Permission denied (publickey)` aunque la llave estaba copiada | El cliente solo probó nombres de llave por defecto (`id_rsa`, `id_ed25519`…); la llave tenía otro nombre | Probar con `-i` y dejarlo fijo en `~/.ssh/config` |

```text
# ~/.ssh/config
Host 192.168.124.*
    IdentityFile ~/.ssh/lab_master
    User <usuario>
```

Tip: `ssh -v` muestra cada llave que el cliente intenta ("Will attempt key: …"); es la forma más rápida de ver este tipo de problema.

## Aprendizajes
- Netplan reemplazó el esquema viejo "ifconfig + gateway"; los valores son listas YAML entre `[ ]`.
- Misma subred es lo primero a revisar cuando solo algunos pares de hosts se comunican.
- Leer el log del cliente antes de tocar el servidor.
