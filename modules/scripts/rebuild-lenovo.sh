#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"

cd "$DOTFILES_DIR"

echo "==> Staging local changes..."
git add -A

if ! git diff-index --quiet HEAD --; then
    echo "==> Committing local changes..."
    git commit -m "rebuild(lenovo): update configuration [$(date +'%Y-%m-%d %H:%M:%S')]"
else
    echo "==> No uncommitted changes."
fi

echo "==> Pushing to origin/master..."
git push origin master

echo "==> Rebuilding system locally on lenovo..."
sudo nixos-rebuild switch --flake .#lenovo

echo "==> Local rebuild on lenovo complete!"
