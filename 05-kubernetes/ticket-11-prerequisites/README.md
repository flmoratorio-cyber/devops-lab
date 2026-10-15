# Ticket 11 — Kubernetes prerequisites and node preparation with Ansible

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Part 1 — Why these prerequisites (theory)

**1. Swap must be off.** The kubelet refuses to start if it detects active swap. The reason is *predictability*: pod `requests`/`limits` are enforced through cgroups, and swap lets a container exceed its memory limit by paging to disk, hiding memory pressure from the scheduler and making eviction/OOM behaviour non-deterministic.

**2. `overlay`, `br_netfilter` and `ip_forward`.**
- `overlay` — the overlayfs storage driver used by the container runtime.
- `br_netfilter` + `net.bridge.bridge-nf-call-iptables=1` — makes traffic crossing Linux bridges visible to iptables, which `kube-proxy` and CNI rely on for Services and network policy.
- `net.ipv4.ip_forward=1` — lets the node route packets between pods, nodes and the outside; without it the `FORWARD` chain ([ticket 02.5](../../01-linux-networking/ticket-02.5-dns-netcat-iptables)) never sees that traffic.

**3. kubeadm vs k3s.** k3s is a lightweight single binary: fewer resources, quick setup, but hides components. kubeadm is upstream Kubernetes: more resources and steps, but you see and control every component (etcd, API server, scheduler, controller manager, kubelet) — better for learning the architecture. Decision for this lab: **kubeadm**.

## Part 2 — Automating the prerequisites
Playbook: [`ansible/prepare_k8s_nodes.yaml`](ansible/prepare_k8s_nodes.yaml) · inventory: [`ansible/inventory.example.ini`](ansible/inventory.example.ini)

```bash
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory.ini ansible/prepare_k8s_nodes.yaml --limit master   # canary
ansible-playbook -i ansible/inventory.ini ansible/prepare_k8s_nodes.yaml                  # whole cluster
```

### Audit on the live system (don't trust the tool's output alone)
```bash
free -h                      # Swap: 0B
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables     # both = 1
# across the cluster:
ansible -i inventory.ini k8s_cluster -m shell -a "free -m | grep -i swap" -b
```

## Troubleshooting log

### Swap came back after a reboot
Verification after restarting the VMs showed `Swap: 2819` on every node although the playbook had "succeeded". `grep swap /etc/fstab` showed `/swap.img none swap sw 0 0` **still active**.

- **Root cause:** `swapoff -a` only lasts until reboot, and the `/etc/fstab` entry was never commented out. The first version used `sed -i '/ swap / s/^/#/'`, which only matches a *single literal space* on each side of `swap`; the fstab columns here are separated by tabs / runs of spaces, which most likely explains why nothing matched — and since the task was a raw `shell`, it reported `changed` regardless.
- **Fix:** `ansible.builtin.replace` with a `\s+` regex (as in the playbook), a `when` guard on the live swap size, and dedicated modules (`copy`, `modprobe`, `sysctl`) instead of `shell`, so re-runs report `changed=0`.

### `blockinfile` failed: file not found
`blockinfile` does not create a missing file by default — it needs `create: true`. Replaced by `copy` with explicit `content` since the file is fully owned by this playbook.

### Facts as variables
Use `ansible_facts['swaptotal_mb']` instead of the legacy injected `ansible_swaptotal_mb`; the latter relies on a variable-injection behaviour that is deprecated.

### Privilege prompts
Running against the control node itself (`ansible_connection=local`) asked for a sudo password until passwordless sudo was configured with `visudo` (see [ticket 05](../../03-ansible/ticket-05-ansible-automation)).

## Next
Ticket 12 — containerd + kubeadm/kubelet/kubectl, `kubeadm init`, CNI, join workers, first Deployment and Service.
