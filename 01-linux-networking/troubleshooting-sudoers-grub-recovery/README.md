# Recovering from a broken `sudoers` (GRUB root shell)

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Scenario
While enabling passwordless sudo for the automation user, a malformed line was appended to `/etc/sudoers` with `tee`. `sudo` stopped working entirely, so the file could not be fixed from inside the OS.

## Recovery (from the hypervisor console, not SSH)
1. Reboot the VM. Hold `Shift` (or tap `Esc`) right after the VMware logo to open the GRUB menu.
2. Highlight the Ubuntu entry, press `e`, go to the line starting with `linux` and append at the end:
   ```text
   rw init=/bin/bash
   ```
   Boot with `Ctrl+X` / `F10`. You land in a root shell with no password.
3. Fix the file with the safe editor and remove the bad line:
   ```bash
   visudo
   ```
4. Reboot normally (`exec /sbin/init`, or reset from the hypervisor).

Expected final line for the automation user:

```text
<user> ALL=(ALL) NOPASSWD:ALL
```

## Prevention
- **Never edit `/etc/sudoers` with `tee`/`echo >>`/a plain editor.** Use `visudo`, which validates syntax before saving.
- Better: drop-in files, each validated:
  ```bash
  echo '<user> ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/90-lab
  sudo visudo -cf /etc/sudoers.d/90-lab
  sudo chmod 440 /etc/sudoers.d/90-lab
  ```
- Keep a second root-capable session open while editing privilege config.

## Security note
Anyone with console access can do this (GRUB edit → root). That is why physical/hypervisor access must be protected, and why production systems use a GRUB password and disk encryption.
