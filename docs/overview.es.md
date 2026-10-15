# Laboratorio Privado DevOps & Cloud Engineering
> **Documentación de Proyecto**: Registro de Arquitectura, Automatización y Orquestación para GitHub.

---

## 1. Módulo: Docker Engine & Contenedores

### Qué es
Motor de virtualización a nivel de sistema operativo que permite empaquetar aplicaciones y sus dependencias en contenedores aislados.
Aprovecha características nativas del Kernel de Linux como *cgroups* y *namespaces* para compartir el Kernel manteniendo aislamiento de procesos y recursos.

### Arquitectura
```text
+-----------------------------------------------------------------------+
| CLI de Docker (docker run, docker ps, docker build)                   |
+-----------------------------------------------------------------------+
                                   │
                                   ▼ (Socket UNIX / API REST)
+-----------------------------------------------------------------------+
| Daemon de Docker (dockerd)                                            |
+-----------------------------------------------------------------------+
                                   │
                                   ▼
+-----------------------------------------------------------------------+
| Container Runtime Interface (containerd / runc)                       |
+-----------------------------------------------------------------------+
                                   │
                                   ▼
+-----------------------------------------------------------------------+
| KERNEL LINUX (Namespaces: PID, NET, IPC | Cgroups: CPU, RAM, I/O)    |
+-----------------------------------------------------------------------+
```

### Stack
* **Engine & Runtime**: Docker Engine CE, `containerd.io`, `runc`.
* **Imágenes Base**: Nginx, Alpine Linux, Ubuntu.
* **Redes**: Bridge Networks (`docker_network` custom con DNS embebido).
* **Almacenamiento**: Bind Mounts, Docker Named Volumes (`docker_volume`).

### Incidentes / decisiones
* **Síntoma**: Contenedor finaliza de inmediato con `Exited (1)` o `Exited (127)`.
  * **Causa**: Orden erróneo de parámetros en el comando `docker run` o uso de imágenes de terceros no oficiales con configuraciones rotas (`nginx.conf` buscando hosts inexistentes).
  * **Solución**: Usar la imagen oficial `nginx:latest`, corregir el orden de argumentos (`docker run -d --name nginx -p 8080:80 nginx`) y auditar los logs con `docker logs <container_id>`.
* **Síntoma**: `Permission denied` al ejecutar comandos de Docker sin `sudo`.
  * **Causa**: El usuario no pertenece al grupo de sistema `docker`.
  * **Solución**: Ejecutar `sudo usermod -aG docker $USER` y recargar los grupos en la sesión activa con `newgrp docker`.
* **Síntoma**: Error de firma OpenPGP `NO_PUBKEY 7EA0A9C3F273FCD8` al actualizar repositorios en APT.
  * **Causa**: Repositorios residuales mal configurados o falta del llavero GPG oficial en la ruta del sistema.
  * **Solución**: Extirpar archivos residuales en `/etc/apt/sources.list.d/` e inyectar la llave oficial en `/etc/apt/keyrings/docker.asc` con permisos `0644`.

### Estado real
* **Implementado en el laboratorio**: Motor Docker instalado, asegurado y operativo en el nodo `master` y en los 4 nodos trabajadores (`wk1`, `wk2`, `wk3`, `wk4`).
* **En Plan**: Mantenimiento de contenedores como *runtime* delegado (`CRI containerd`) dentro del clúster de Kubernetes.

---

## 2. Módulo: Ansible & Automatización Idempotente

### Qué es
Herramienta de orquestación y gestión de configuración sin agente (*agentless*) que automatiza la administración de infraestructura.
Utiliza código declarativo en formato YAML (Playbooks) ejecutado a través de conexiones SSH seguras y Python en los nodos remotos.

### Arquitectura
```text
+-----------------------------------------------------------------------+
| NODO DE CONTROL (master)                                              |
|   - Playbooks (.yaml)                                                 |
|   - Inventario Jerárquico (workers_inventario.ini / @k8s_cluster)    |
|   - Módulos Nativos (apt, posix.sysctl, blockinfile, user, systemd)   |
+-----------------------------------------------------------------------+
                                   │
                                   ├─── SSH (Llave RSA / NOPASSWD) ───► [ Worker 1 (wk1) ]
                                   ├─── SSH (Llave RSA / NOPASSWD) ───► [ Worker 2 (wk2) ]
                                   ├─── SSH (Llave RSA / NOPASSWD) ───► [ Worker 3 (wk3) ]
                                   └─── SSH (Llave RSA / NOPASSWD) ───► [ Worker 4 (wk4) ]
```

### Stack
* **Core**: Ansible Core, Python 3.12+.
* **Protocolo de Comunicación**: OpenSSH con llaves RSA y `sudo` escalado.
* **Módulos Clave**: `ansible.builtin.apt`, `ansible.builtin.copy`, `ansible.builtin.get_url`, `ansible.posix.sysctl`, `ansible.builtin.blockinfile`, `ansible.builtin.systemd`.

### Incidentes / decisiones
* **Síntoma**: Fallo de conexión `sudo: interactive authentication is required` o `Premature end of stream`.
  * **Causa**: El usuario en el nodo remoto o master requiere contraseña interactiva para escalar privilegios con `sudo`.
  * **Solución**: Configurar la regla `NOPASSWD:ALL` en `/etc/sudoers` usando `sudo visudo` o pasar el flag `-K` (`--ask-become-pass`) en la consola.
* **Síntoma**: Tarea aborta con `Path /etc/modules-load.d/k8s.conf does not exist!`.
  * **Causa**: El módulo `ansible.builtin.blockinfile` no crea el archivo destino si este no existe previamente.
  * **Solución**: Agregar la directiva explícita `create: true` en los parámetros de la tarea en el Playbook.
* **Síntoma**: Imposibilidad de alcanzar la idempotencia pura (`changed=1` en cada ejecución sucesiva).
  * **Causa**: Conflicto entre una tarea previa que borraba el archivo de repositorio (`file: state=absent`) y la tarea subsiguiente que lo volvía a crear.
  * **Solución**: Eliminar la tarea destructiva de limpieza del Playbook principal para permitir que el módulo declarativo verifique el estado existente sin forzar recreación.

### Estado real
* **Implementado en el laboratorio**: Inventario jerárquico configurado (`@k8s_cluster` -> `control_plane` + `workers`), Playbook de instalación idempotente de Docker ejecutado y Playbook de preparación de nodos de Kubernetes (`04_nodos_preparar-k8.yaml`: desactivación de Swap, carga de módulos `overlay`/`br_netfilter` y sysctl `net.ipv4.ip_forward=1`).
* **En Plan**: Playbook automatizado para la instalación de binarios `kubeadm`, `kubelet` y `kubectl` en toda la flota (Ticket 12).

---

## 3. Módulo: Terraform & Infraestructura como Código (IaC)

### Qué es
Plataforma de Infraestructura como Código (IaC) que permite declarar, aprovisionar y gestionar el ciclo de vida completo de recursos de forma inmutable.
Usa HashiCorp Configuration Language (HCL) para construir un grafo de dependencias y mantener el estado real sincronizado contra el código.

### Arquitectura
```text
+-----------------------------------------------------------------------+
| CÓDIGO DECLARATIVO (main.tf, variables.tf, outputs.tf)                 |
+-----------------------------------------------------------------------+
                                   │
                                   ▼ (terraform plan / apply)
+-----------------------------------------------------------------------+
| GRAFO DE DEPENDENCIAS Y ARCHIVO DE ESTADO (terraform.tfstate)          |
+-----------------------------------------------------------------------+
                                   │
                                   ▼ (Provider Aliases vía SSH)
          ┌────────────────────────┼────────────────────────┐
          ▼                        ▼                        ▼
[ Provider Docker: wk1 ] [ Provider Docker: wk2 ] [ Provider Docker: wk3..4 ]
```

### Stack
* **Herramienta**: Terraform CLI.
* **Lenguaje**: HCL (HashiCorp Configuration Language).
* **Provider**: `kreuzwerker/docker` (v4.2.0).
* **Mecanismo de Conexión**: Túneles SSH (`host = "ssh://<user>@wkX"`).

### Incidentes / decisiones
* **Síntoma**: Error `Reference to undeclared resource docker.image.nginx.image_id`.
  * **Causa**: Error de sintaxis en HCL al usar un punto en lugar de guion bajo para hacer referencia al tipo de recurso (`docker.image` vs `docker_image`).
  * **Solución**: Corregir la referencia a `docker_image.nginx.image_id`.
* **Síntoma**: Error `Unable to remove Docker image: conflict - container is using its referenced image`.
  * **Causa**: Existencia de contenedores huérfanos creados manualmente vía CLI (`docker run`) que retenían la imagen que Terraform intentaba purgar (`keep_locally = false`).
  * **Solución**: Ejecutar purga de contenedores detenidos en los workers mediante comandos ad-hoc de Ansible (`docker system prune -af`) para desacoplar el estado.
* **Síntoma**: Contenedores desplegándose localmente en `master` en lugar de distribuirse en los nodos `workers`.
  * **Causa**: Omisión del meta-argumento `provider = docker.wkX` en los bloques `docker_container`.
  * **Solución**: Declarar explícitamente el proveedor con *alias* correspondiente en cada bloque de contenedor (`provider = docker.wk1`).

### Estado real
* **Implementado en el laboratorio**: Despliegue distribuido multinodo en paralelo sobre los 4 workers mediante *provider aliases*, redes privadas declarativas (`docker_network`), volúmenes persitentes (`docker_volume`) y purga completa del entorno de pruebas.
* **En Plan**: Aprovisionamiento declarativo de infraestructura Cloud (OCI / AWS) cuando se expanda el laboratorio.

---

## 4. Módulo: Kubernetes & Orquestación de Contenedores

### Qué es
Plataforma de orquestación distribuida de contenedores diseñada para automatizar el despliegue, escalado, alta disponibilidad y gestión de aplicaciones empaquetadas.
Coordina un plano de control centralizado (*Control Plane*) con múltiples nodos trabajadores (*Workers*) mediante una red superpuesta.

### Arquitectura
```text
+-----------------------------------------------------------------------+
| PLANO DE CONTROL / MASTER (master)                                    |
|   [API Server] <---> [etcd] <---> [Scheduler] <---> [Controller Mgr] |
+-----------------------------------------------------------------------+
                                   │
                                   ▼ (Red Superpuesta CNI / Calico)
          ┌────────────────────────┴────────────────────────┐
          ▼                                                 ▼
+-----------------------------------+             +-------------------------+
| NODO WORKER (wk1)                 |             | NODOS WORKERS (wk2..wk4)|
|   [kubelet] <---> [kube-proxy]    |             |   [kubelet] [kube-proxy]|
|   [Container Runtime: containerd] |             |   [Container Runtime]   |
+-----------------------------------+             +-------------------------+
```

### Stack
* **Herramientas de Despliegue**: Kubeadm, Kubelet, Kubectl.
* **Container Runtime (CRI)**: Containerd.
* **Redes (CNI)**: Calico / Flannel.
* **Requisitos del Kernel**: Desactivación de Swap, Módulos `overlay` y `br_netfilter`, parámetros `net.ipv4.ip_forward=1` y `net.bridge.bridge-nf-call-iptables=1`.

### Incidentes / decisiones
* **Síntoma**: Error `cannot stat /proc/sys/net/bridge/...: No such file or directory` al ejecutar `sysctl --system`.
  * **Causa**: Intento de aplicar parámetros de red de puente sin haber cargado previamente el módulo del kernel `br_netfilter` en la RAM.
  * **Solución**: Reordenar la secuencia en el Playbook de Ansible para ejecutar `modprobe overlay` y `modprobe br_netfilter` antes de invocar el módulo `sysctl`.
* **Síntoma**: Incompatibilidad y fallo de arranque del servicio Kubelet en los nodos.
  * **Causa**: Presencia de memoria de intercambio (*Swap*) activa en el sistema operativo Linux.
  * **Solución**: Desactivación en caliente con `swapoff -a` y modificación permanente en `/etc/fstab` deshabilitando la partición de Swap.
* **Síntoma**: Mensaje `skipping: no hosts matched` en Ansible al intentar aplicar cambios en el nodo `master`.
  * **Causa**: Incompatibilidad entre el filtro `--limit master` y la directiva `hosts: workers` en la cabecera del Playbook.
  * **Solución**: Reestructurar la jerarquía del inventario creando el grupo sombrilla `k8s_cluster:children` (`control_plane` + `workers`) y definir `hosts: k8s_cluster` en el Playbook.

### Estado real
* **Implementado en el laboratorio**: Preparación de nodos completada (Ticket 11): Playbook de Ansible 04_nodos_preparar-k8.yaml desplegado en `master` y en los 4 `workers`.
* > El Clúster aun no está inicializado <
* **En Plan**:
  * **Ticket 12**: Instalación de binarios K8s (`kubeadm`, `kubelet`, `kubectl`) y configuración de `containerd`.
  * **Ticket 13**: Inicialización del Control Plane (`kubeadm init`) y despliegue del CNI.
  * **Ticket 14**: Unificación del clúster (`kubeadm join` de los 4 workers).
  * **Ticket 15**: Despliegue de objetos nativos (Pods, Deployments, Services, Ingress).
