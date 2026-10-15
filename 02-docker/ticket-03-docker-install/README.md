# Ticket 03 — Docker Engine from the official repository

🇬🇧 English · [🇦🇷 Español](README.es.md)

## Objective
Install Docker Engine the production way — from Docker's own apt repository, not Ubuntu's `docker.io` package (older, differently maintained) — and understand each component before automating it.

## Steps
1. **Remove conflicting packages** → [`scripts/docker_0_remove_conflicts.sh`](scripts/docker_0_remove_conflicts.sh)
2. **Add the official repo + GPG key** → [`scripts/docker_1_repository.sh`](scripts/docker_1_repository.sh)
3. **Install** `docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` → [`scripts/docker_2_install.sh`](scripts/docker_2_install.sh)
4. **Run as a normal user**: `sudo usermod -aG docker <user>`
5. **Validate**: `docker run hello-world`

Distributing the scripts by hand, node by node:

```bash
scp scripts/docker_0_remove_conflicts.sh wk1:/home/<user>/
ssh -t wk1 'bash /home/<user>/docker_0_remove_conflicts.sh'
```

## Gotcha: group membership needs a new login
After `usermod -aG docker`, `docker run` still fails with *permission denied* in the current session: group membership is evaluated at login. Log out and back in, or run `newgrp docker`.

## Why this is the last manual install
Running the same scripts on four workers by hand is slow and error-prone — there is no way to know every node ended in the same state. That friction is exactly the problem **Ansible** solves → [ticket 05](../../03-ansible/ticket-05-ansible-automation).

## Takeaways
- Use the vendor repository for production runtimes; remove distro leftovers first.
- Docker group = root-equivalent on that host; grant it deliberately.
