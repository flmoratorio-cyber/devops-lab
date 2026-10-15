#!/usr/bin/env bash
# Remove distro packages that conflict with Docker's official packages.
set -euo pipefail
sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 \
  docker-doc docker-buildx podman-docker containerd runc 2>/dev/null | cut -f1) || true
