# Ticket 02 — SSH hardening on the workers

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Make the SSH key the **only** way into the workers: disable password authentication and root login.

## Configuration
Edit `/etc/ssh/sshd_config` (and check `/etc/ssh/sshd_config.d/*.conf`, which can override it):

```text
PasswordAuthentication no
PermitRootLogin no
```

```bash
sudo sshd -t                       # validate syntax before restarting
sudo systemctl restart ssh
```

## Audit (failure test)
From `master`, force the client to ignore the key. The server must reject it immediately:

```bash
ssh -o PubkeyAuthentication=no <user>@<worker-ip>
# Permission denied (publickey).
```

> **Safety rule:** never close the working SSH session while changing SSH settings. Open a second terminal to test; if you locked yourself out, the first one is still there to revert.

## Troubleshooting log
- On Ubuntu the effective value may live in a drop-in under `/etc/ssh/sshd_config.d/`, which takes precedence over the main file (first match wins). On the workers the setting was changed in that drop-in. Check the effective config with `sudo sshd -T | grep -i passwordauthentication`.

## Cloning workers (wk3, wk4 from wk2)
Cloned VMs carry the identity of the original. Checklist per clone:

```bash
sudo hostnamectl set-hostname wk3
passwd                                          # new password per node
sudo rm /etc/machine-id && sudo systemd-machine-id-setup   # unique machine-id
sudo rm /etc/ssh/ssh_host_* && sudo dpkg-reconfigure openssh-server   # new host keys
# update the NIC MAC in the hypervisor / netplan, then set the new static IP
```

Why the `machine-id` matters: identical IDs on cloned machines make some DHCP servers hand out the same lease and confuse centralized log forwarding.

## Takeaways
- Always validate (`sshd -t`) and keep a second session open.
- Test the *negative* case: security controls need a failing test, not only a passing one.
