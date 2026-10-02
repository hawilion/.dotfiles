#!/usr/bin/env bash
set -euo pipefail

echo "Rebuilding Lenovo locally..."
sudo nixos-rebuild switch --flake .#lenovo

echo "Lenovo rebuild complete!"
