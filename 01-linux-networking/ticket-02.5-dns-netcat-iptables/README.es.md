# Ticket 02.5 — DNS local, netcat y cadenas de iptables

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Llegar a los nodos por nombre, probar puertos TCP reales (no solo ICMP) y entender las cadenas de iptables que usan Docker y Kubernetes.

## 1. Resolución local de nombres (`/etc/hosts`)

```bash
echo "192.168.124.101 wk1" | sudo tee -a /etc/hosts > /dev/null
```

**Por qué falla `sudo echo "..." >> /etc/hosts`:** la redirección (`>>`) la hace *tu* shell con *tu* usuario, no `sudo`. Con `tee -a` la escritura la hace un proceso que corre como root (`-a` = append; `> /dev/null` oculta el eco de tee).

En remoto, sin entrar al nodo (comillas simples para que el pipe se ejecute en el nodo, `-t` para el prompt de sudo):

```bash
ssh -t wk1 'echo "192.168.124.10 master" | sudo tee -a /etc/hosts'
```

## 2. Dos errores de SSH para leer con atención

**`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`** — la host key guardada en `known_hosts` ya no coincide con el nodo (VMs clonadas / IPs reutilizadas). Verificar que sea esperado y borrar la entrada vieja:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.124.101
```

**`Permission denied (publickey)` al usar el hostname** — el bloque `Host 192.168.124.*` de `~/.ssh/config` solo coincidía con IPs. Se arregla incluyendo también los nombres:

```text
Host 192.168.124.* wk*
    IdentityFile ~/.ssh/lab_master
    User <usuario>
```

## 3. Pruebas de capa 4 con netcat

`ping` solo prueba ICMP (L3). Un firewall puede dejar pasar el ping y bloquear el servicio.

```bash
nc -zv wk1 22        # -z: solo escanear, sin datos   -v: resultado detallado
```

## 4. Cadenas de iptables

```bash
sudo iptables -L -n -v      # -n numérico, -v contadores e interfaces
```

| Cadena | Tráfico | Ejemplo |
|--------|---------|---------|
| `INPUT` | Paquetes destinados **a este nodo** | alguien entra por SSH al nodo |
| `OUTPUT` | Paquetes **generados por este nodo** | el nodo hace ping a otro host |
| `FORWARD` | Paquetes que **atraviesan** el nodo (actúa como router) | tráfico de contenedores/pods que sale del host |

Una tabla vacía con políticas `ACCEPT` es normal en un Ubuntu recién instalado. `FORWARD` es la razón por la que Kubernetes necesita `net.ipv4.ip_forward=1` (ver ticket 11).
