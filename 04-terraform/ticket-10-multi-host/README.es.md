# Ticket 10 — Integrador: alias de provider y despliegue distribuido

[🇬🇧 English](README.md) · 🇦🇷 Español

## Objetivo
Desplegar un Nginx por worker (wk1–wk4) desde una sola configuración de Terraform, cada uno alcanzado por SSH, con un puerto publicado distinto por nodo. Código: [`main.tf`](main.tf) · [`variables.tf`](variables.tf).

## Cómo funciona
- Un bloque `provider "docker"` por nodo, diferenciados por `alias`.
- Cada recurso que debe caer en un nodo declara `provider = docker.<alias>` — **tanto** la imagen **como** el contenedor, porque cada daemon descarga su propia imagen.
- Host y puerto por nodo viven en variables (`host_wk1…`, `port_wk1…`), no en los recursos.

## Por qué el código se repite por nodo
Lo natural sería iterar con `for_each` sobre un mapa de nodos, pero **el argumento `provider` de un recurso debe ser estático**: la configuración del provider no se puede elegir dinámicamente por instancia. Por eso se usa el patrón de un bloque por nodo (o, en escenarios grandes, un módulo hijo invocado una vez por provider).

## Validación (con Ansible, todos los nodos a la vez)
```bash
terraform init && terraform plan && terraform apply

ansible -i inventory.ini servers -m command -a "docker ps" --become          # en paralelo
ansible -i inventory.ini servers -m command -a "docker ps" --become -f 1     # secuencial (-f 1 = un fork)

terraform destroy
ansible -i inventory.ini servers -m command -a "docker ps -a" --become       # todo vacío: baja limpia
```
Resultado: un contenedor por worker, puertos 8081–8084 y todo limpio tras `destroy`.

## Aprendizajes
- Un solo plan/apply orquesta cuatro hosts; el state registra qué provider es dueño de qué.
- Ansible ad-hoc es el auditor independiente de lo que Terraform dice haber hecho.
- `destroy` + verificación demuestra que el código es la única fuente de verdad.
