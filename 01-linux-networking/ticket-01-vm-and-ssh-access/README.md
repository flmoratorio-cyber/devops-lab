# Ticket 01 — VMs, static IPs and key-based SSH

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Bring up the base of the lab: Ubuntu Server VMs that can reach each other and the internet, with passwordless SSH from the control node (`master`) to every worker. Ansible and Terraform will depend on this later.

## What was done
1. Created the VMs (Ubuntu Server) on a host-only network (`vmnet1`, `192.168.124.0/24`).
2. Assigned static IPs with netplan (`/etc/netplan/*.yaml`, then `sudo netplan apply`).
3. Verified L2/L3 connectivity between nodes.
4. Checked the SSH server: `systemctl status ssh` and `ss -tuln | grep :22`.
5. Generated a key pair on `master` and copied the public key to each worker.

```bash
# on master
ssh-keygen -t ed25519 -f ~/.ssh/lab_master
ssh-copy-id -i ~/.ssh/lab_master.pub <user>@192.168.124.101
ssh -i ~/.ssh/lab_master <user>@192.168.124.101      # first test
```

Static IP example (`/etc/netplan/50-lab.yaml`):

```yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses: [192.168.124.10/24]
```

## Troubleshooting log

| Symptom | Cause | Fix |
|---------|-------|-----|
| `master` ↔ workers: no reply, but workers reach each other | Master and workers were in different IP segments | Put every node in the same subnet |
| `ssh`: network unreachable | Typo in the worker IP address | Verify with `ip a show <iface>` on the target and retype |
| `Permission denied (publickey)` although the key was copied | The client only tried default key names (`id_rsa`, `id_ed25519`…); the key had a custom name | Test with `-i`, then make it permanent in `~/.ssh/config` |

```text
# ~/.ssh/config
Host 192.168.124.*
    IdentityFile ~/.ssh/lab_master
    User <user>
```

Tip: `ssh -v` prints every key the client tries ("Will attempt key: …") and is the fastest way to see this class of problem.

## Takeaways
- Netplan replaced the old "ifconfig + gateway" workflow; values are YAML lists in `[ ]`.
- Same subnet is the first thing to check when only some pairs of hosts talk.
- Read the client log before changing the server.
