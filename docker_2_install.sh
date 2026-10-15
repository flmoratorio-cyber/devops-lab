#!/usr/bin/env bash
set -euo pipefail
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
systemctl is-active docker
