#!/usr/bin/env bash
set -euo pipefail

echo "Building and deploying to llama from Lenovo..."
nixos-rebuild switch --flake .#llama --target-host mike@llama --elevate=sudo --ask-elevate-password

echo "Deployment to llama complete!"
