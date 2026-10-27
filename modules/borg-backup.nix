{ config, pkgs, lib, ... }:

let
  sendAlert = ''
    send_alert() {
      local status="$1"
      local msg="$2"
      local title="Lenovo Borg Backup"
      local priority="default"

      if [ "$status" = "error" ]; then
        priority="high"
        title="Borg Backup FAILURE"
      fi

      ${pkgs.curl}/bin/curl -s \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: backup,lenovo" \
        -d "$msg" \
        https://ntfy.sh/mike-lenovo-borg-backups || true
    }
  '';
in
{
  # ---------------------------------------------------------------------------
  # 1. Local Borg Backup Service & Timer (/var/lib/borg-local)
  # ---------------------------------------------------------------------------
  systemd.services.borg-backup-lenovo-local = {
    description = "Automated Local Borg Backup for Lenovo State";
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    path = with pkgs; [ borgbackup coreutils curl ];
    script = ''
      set -euo pipefail
      ${sendAlert}

      export BORG_PASSPHRASE="$(cat /run/secrets/borg_passphrase)"
      export BORG_REPO="/var/lib/borg-local"

      echo "Starting local lenovo state backup..."
      if borg create \
        --stats \
        --compression zstd \
        --exclude '/home/mike/.cache' \
        ::"lenovo-local-{now:%Y-%m-%d-%H%M%S}" \
        /home/mike \
        /etc/ssh/ssh_host_ed25519_key; then

        echo "Pruning old local archives..."
        borg prune \
          --list \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6 || true

        echo "Local backup succeeded."
        send_alert "info" "SUCCESS: Local backup completed on lenovo."
      else
        echo "Local backup failed!" >&2
        send_alert "error" "FAILED: Local backup on lenovo encountered errors."
        exit 1
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.borg-backup-lenovo-local = {
    description = "Automated Local Borg Backup for Lenovo Daily at 1:30 PM";
    timerConfig = {
      OnCalendar = "*-*-* 13:30:00";
      Persistent = true;
      Unit = "borg-backup-lenovo-local.service";
    };
    wantedBy = [ "timers.target" ];
  };

  # ---------------------------------------------------------------------------
  # 2. Remote Borg Backup Service & Timer (nixos-server)
  # ---------------------------------------------------------------------------
  systemd.services.borg-backup-lenovo = {
    description = "Automated Borg Backup for Lenovo State (Remote)";
    after = [ "network.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    path = with pkgs; [ borgbackup openssh netcat coreutils curl ];

    script = ''
      set -euo pipefail
      ${sendAlert}

      export BORG_PASSPHRASE="$(cat /run/secrets/borg_passphrase)"
      export BORG_REPO="ssh://root@nixos-server/var/lib/borg-lenovo"
      export BORG_RSH="ssh -i /etc/ssh/ssh_host_ed25519_key -o IdentitiesOnly=yes -o PreferredAuthentications=publickey"

      set +e
      nc -z -w 5 nixos-server 22
      CONN_STATUS=$?
      set -e

      if [ $CONN_STATUS -ne 0 ]; then
        echo "nixos-server unreachable on port 22. Skipping remote backup." >&2
        send_alert "error" "WARNING: nixos-server SSH unreachable. Remote backup skipped."
        exit 0
      fi

      echo "Starting lenovo state backup to nixos-server..."
      if borg create \
        --stats \
        --compression zstd \
        --exclude '/home/mike/.cache' \
        ::"lenovo-{now:%Y-%m-%d-%H%M%S}" \
        /home/mike \
        /etc/ssh/ssh_host_ed25519_key; then

        echo "Pruning old remote archives on nixos-server..."
        borg prune \
          --list \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6 || true

        echo "Backup to nixos-server succeeded."
        send_alert "info" "SUCCESS: Remote backup to nixos-server completed."
      else
        echo "Backup to nixos-server failed!" >&2
        send_alert "error" "FAILED: Remote backup to nixos-server failed."
        exit 1
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.borg-backup-lenovo = {
    description = "Automated Remote Borg Backup for Lenovo Daily at 3:00 PM";
    timerConfig = {
      OnCalendar = "*-*-* 15:00:00";
      Persistent = true;
      Unit = "borg-backup-lenovo.service";
    };
    wantedBy = [ "timers.target" ];
  };
}
