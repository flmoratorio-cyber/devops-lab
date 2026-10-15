# Recuperación de un `sudoers` roto (shell root desde GRUB)

[🇬🇧 English](README.md) · 🇦🇷 Español

## Escenario
Al habilitar sudo sin contraseña para el usuario de automatización, se agregó una línea mal formada a `/etc/sudoers` con `tee`. `sudo` dejó de funcionar y el archivo no se podía corregir desde el propio sistema.

## Recuperación (desde la consola del hipervisor, no por SSH)
1. Reiniciar la VM. Mantener `Shift` (o presionar `Esc`) apenas termina el logo de VMware para abrir el menú de GRUB.
2. Resaltar la entrada de Ubuntu, presionar `e`, ir a la línea que empieza con `linux` y agregar al final:
   ```text
   rw init=/bin/bash
   ```
   Iniciar con `Ctrl+X` / `F10`. Se entra a una shell de root sin contraseña.
3. Corregir con el editor seguro y borrar la línea errónea:
   ```bash
   visudo
   ```
4. Reiniciar normal (`exec /sbin/init`, o reset desde el hipervisor).

Línea final esperada para el usuario de automatización:

```text
<usuario> ALL=(ALL) NOPASSWD:ALL
```

## Prevención
- **Nunca editar `/etc/sudoers` con `tee`/`echo >>`/un editor común.** Usar `visudo`, que valida la sintaxis antes de guardar.
- Mejor aún: archivos drop-in, cada uno validado:
  ```bash
  echo '<usuario> ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/90-lab
  sudo visudo -cf /etc/sudoers.d/90-lab
  sudo chmod 440 /etc/sudoers.d/90-lab
  ```
- Mantener una segunda sesión con privilegios abierta mientras se edita la config de privilegios.

## Nota de seguridad
Cualquiera con acceso a la consola puede hacer esto (editar GRUB → root). Por eso hay que proteger el acceso físico/al hipervisor, y por eso en producción se usa contraseña de GRUB y cifrado de disco.
