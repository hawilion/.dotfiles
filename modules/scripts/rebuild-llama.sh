#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"
REMOTE_HOST="mike@192.168.79.86"
REMOTE_DIR="~/.dotfiles"

cd "$DOTFILES_DIR"

echo "==> Staging local changes..."
git add -A

if ! git diff-index --quiet HEAD --; then
    echo "==> Committing local changes..."
    git commit -m "rebuild(llama): update configuration [$(date +'%Y-%m-%d %H:%M:%S')]"
else
    echo "==> No uncommitted changes."
fi

echo "==> Pushing to origin/master..."
git push origin master

echo "==> Updating repository on llama..."
ssh "$REMOTE_HOST" "cd $REMOTE_DIR && git pull origin master"

echo "==> Rebuilding system on llama..."
sudo nixos-rebuild switch \
  --flake .#llama \
  --target-host "$REMOTE_HOST" \
  --build-host "$REMOTE_HOST" \
  --elevate=sudo \
  --ask-elevate-password

echo "==> Deployment to llama complete!"
