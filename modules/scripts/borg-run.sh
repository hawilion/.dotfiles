#!/usr/bin/env bash
set -euo pipefail
export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"

BORG_PASSPHRASE=$(cat /run/secrets/borg_passphrase)
export BORG_PASSPHRASE

# Define target backup repositories
REPOS=(
  "ssh://nixos-server/var/lib/borg-lenovo"
  "mike@llama:/home/mike/backups/lenovo"
)

FAILED_REPOS=()

for REPO in "${REPOS[@]}"; do
  # Extract hostname/IP for connectivity ping check
  HOST=$(echo "$REPO" | sed -E 's#(ssh://)?([^@]+@)?([^:/]+).*#\3#')

  echo "========================================"
  echo "Processing backup for: $HOST ($REPO)"
  echo "========================================"

  HOST_REACHABLE=false
  for _i in {1..6}; do
    if ping -c 1 -W 5 "$HOST" &>/dev/null; then
      HOST_REACHABLE=true
      break
    fi
    echo "Waiting for $HOST..."
    sleep 10
  done

  if [[ "$HOST_REACHABLE" != "true" ]]; stream; then
    echo "Host $HOST unreachable after retries. Skipping..." >&2
    FAILED_REPOS+=("$HOST (Unreachable)")
    continue
  fi

  export BORG_REPO="$REPO"

  echo "Starting Borg backup to $HOST..."
  if borg create \
    --stats \
    --compression zstd \
    --exclude '/home/mike/.cache' \
    --exclude '/home/mike/.nix-profile' \
    ::"lenovo-{now:%Y-%m-%d-%H%M%S}" \
    /home/mike/.dotfiles \
    /home/mike; then
    echo "Backup to $HOST succeeded."
  else
    echo "Backup to $HOST failed." >&2
    FAILED_REPOS+=("$HOST (Failed)")
  fi
done

if [ ${#FAILED_REPOS[@]} -eq 0 ]; then
  echo "All backups completed successfully!"
  notify-send -u normal -t 0 "Borg Backup" "All backups (nixos-server, llama) completed successfully!"
else
  FAILED_LIST=$(IFS=", "; echo "${FAILED_REPOS[*]}")
  echo "Backup completed with failures: $FAILED_LIST" >&2
  notify-send -u critical "Borg Backup" "Backup issues on: $FAILED_LIST. Check journal logs using 'borg-journal'."
  exit 1
fi
