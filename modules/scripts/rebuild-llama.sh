#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
REMOTE_HOST="llama"
REMOTE_DIR="~/.dotfiles"

cd "$DOTFILES_DIR"

echo "==> Staging local changes..."
git add -A

if ! git diff-index --quiet HEAD --; then
    echo "==> Committing local changes..."
    git commit -m "rebuild(llama): update configuration $(date +'%Y-%m-%d %H:%M:%S')"
else
    echo "==> No uncommitted changes."
fi

echo "==> Pushing to origin/master..."
git push origin master

echo "==> Updating repository on llama..."
ssh "$REMOTE_HOST" "cd $REMOTE_DIR && git pull origin master"

echo "==> Rebuilding system on llama..."
export NIX_SSHOPTS="-o ControlMaster=auto -o ControlPath=~/.ssh/master-%r@%h:%p -o ControlPersist=10m"

nixos-rebuild switch \
  --flake .#llama \
  --target-host "$REMOTE_HOST" \
  --build-host "$REMOTE_HOST" \
  --use-remote-sudo \
  --no-update-lock-file

echo "==> Deployment to llama complete!"
