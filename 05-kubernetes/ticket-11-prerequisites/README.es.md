# Ticket 11 — Prerrequisitos de Kubernetes y preparación de nodos con Ansible

[🇬🇧 English](README.md) · 🇦🇷 Español

## Parte 1 — Por qué estos prerrequisitos (teoría)

**1. El swap debe estar deshabilitado.** El kubelet no arranca si detecta swap activo. El motivo es la *previsibilidad*: los `requests`/`limits` de los pods se aplican con cgroups, y el swap permite que un contenedor exceda su límite de memoria paginando a disco, ocultando la presión de memoria al scheduler y volviendo no determinista el comportamiento de eviction/OOM.

**2. `overlay`, `br_netfilter` e `ip_forward`.**
- `overlay` — el driver de almacenamiento overlayfs que usa el runtime de contenedores.
- `br_netfilter` + `net.bridge.bridge-nf-call-iptables=1` — hace que el tráfico que cruza bridges de Linux sea visible para iptables, de lo que dependen `kube-proxy` y el CNI para Services y network policies.
- `net.ipv4.ip_forward=1` — permite al nodo enrutar paquetes entre pods, nodos y el exterior; sin esto la cadena `FORWARD` ([ticket 02.5](../../01-linux-networking/ticket-02.5-dns-netcat-iptables/README.es.md)) nunca ve ese tráfico.

**3. kubeadm vs k3s.** k3s es un binario único y liviano: menos recursos, instalación rápida, pero oculta componentes. kubeadm es Kubernetes upstream: más recursos y pasos, pero se ve y controla cada componente (etcd, API server, scheduler, controller manager, kubelet) — mejor para aprender la arquitectura. Decisión para este laboratorio: **kubeadm**.

## Parte 2 — Automatizar los prerrequisitos
Playbook: [`ansible/prepare_k8s_nodes.yaml`](ansible/prepare_k8s_nodes.yaml) · inventario: [`ansible/inventory.example.ini`](ansible/inventory.example.ini)

```bash
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory.ini ansible/prepare_k8s_nodes.yaml --limit master   # canario
ansible-playbook -i ansible/inventory.ini ansible/prepare_k8s_nodes.yaml                  # todo el clúster
```

### Auditoría sobre el sistema vivo (no confiar solo en la salida de la herramienta)
```bash
free -h                      # Swap: 0B
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables     # ambos = 1
# en todo el clúster:
ansible -i inventory.ini k8s_cluster -m shell -a "free -m | grep -i swap" -b
```

## Bitácora de troubleshooting

### El swap volvió después de reiniciar
La verificación tras reiniciar las VMs mostró `Swap: 2819` en todos los nodos aunque el playbook había "funcionado". `grep swap /etc/fstab` mostraba `/swap.img none swap sw 0 0` **todavía activo**.

- **Causa raíz:** `swapoff -a` solo dura hasta el reinicio, y la entrada de `/etc/fstab` nunca quedó comentada. La primera versión usaba `sed -i '/ swap / s/^/#/'`, que solo coincide con *un único espacio literal* a cada lado de `swap`; las columnas de fstab acá están separadas por tabs / varios espacios, lo que muy probablemente explica que no coincidiera — y como la tarea era un `shell` crudo, reportaba `changed` igual.
- **Solución:** `ansible.builtin.replace` con regex `\s+` (como en el playbook), una guarda `when` sobre el swap real y módulos específicos (`copy`, `modprobe`, `sysctl`) en lugar de `shell`, para que las re-ejecuciones den `changed=0`.

### `blockinfile` falló: archivo inexistente
`blockinfile` no crea el archivo si falta — requiere `create: true`. Se reemplazó por `copy` con `content` explícito, ya que el archivo es 100% de este playbook.

### Facts como variables
Usar `ansible_facts['swaptotal_mb']` y no la variable inyectada heredada `ansible_swaptotal_mb`; esta última depende de un comportamiento de inyección que está deprecado.

### Prompts de privilegios
Al ejecutar contra el propio nodo de control (`ansible_connection=local`) pedía contraseña de sudo hasta configurar sudo sin contraseña con `visudo` (ver [ticket 05](../../03-ansible/ticket-05-ansible-automation/README.es.md)).

## Siguiente
Ticket 12 — containerd + kubeadm/kubelet/kubectl, `kubeadm init`, CNI, unir workers, primer Deployment y Service.
