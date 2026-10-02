#!/usr/bin/env bash
set -euo pipefail
export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"
export BORG_PASSPHRASE=$(cat /run/secrets/borg_passphrase)
export BORG_REPO="ssh://nixos-server/var/lib/borg-lenovo"

echo "Waiting for nixos-server..."
for i in {1..6}; do
  if ping -c 1 -W 5 nixos-server &>/dev/null; then
    break
  fi
  sleep 10
done

echo "Starting Borg backup..."

if borg create \
  --stats \
  --compression zstd \
  --exclude '/home/mike/.cache' \
  --exclude '/home/mike/.nix-profile' \
  ::"lenovo-{now:%Y-%m-%d-%H%M%S}" \
  /home/mike/.dotfiles \
  /home/mike; then

  echo "Backup succeeded."
  notify-send -u normal -t 0 "Borg Backup" "Backup completed successfully!"
else
  echo "Backup failed." >&2
  notify-send -u critical "Borg Backup" "Backup failed! Check journal logs using 'borg-journal'."
  exit 1
fi
