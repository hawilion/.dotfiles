{ config, pkgs, lib, ... }:

let
  # Shell helper function to send desktop alerts back to lenovo
  notifyLenovo = ''
    send_alert() {
      local status="$1"
      local msg="$2"
      local icon="dialog-information"
      
      if [ "$status" = "error" ]; then
        icon="dialog-error"
      fi

      if ping -c 1 -W 2 lenovo &>/devnull; then
        ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new -i /etc/ssh/ssh_host_ed25519_key root@lenovo \
          "WAYLAND_DISPLAY=wayland-1 DISPLAY=:0 sudo -u mike ${pkgs.libnotify}/bin/notify-send \
            --app-name='Llama Borg Backup' \
            --icon='$icon' \
            'Borg Backup Alert' \
            '$msg'" &>/devnull || true
      fi
    }
  '';
in
{
  # ---------------------------------------------------------------------------
  # 1. Local Borg Backup Service & Timer (/var/lib/borg-local)
  # ---------------------------------------------------------------------------
  systemd.services.borg-backup-llama-local = {
    description = "Automated Local Borg Backup for Llama State";
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    path = with pkgs; [ borgbackup coreutils openssh iputils libnotify ];

    script = ''
      set -euo pipefail
      ${notifyLenovo}

      export BORG_PASSPHRASE="$(cat /run/secrets/borg_passphrase)"
      export BORG_REPO="/var/lib/borg-local"

      echo "Starting local llama state backup..."
      if borg create \
        --stats \
        --compression zstd \
        --exclude '/home/mike/.ollama/models/blobs' \
        --exclude '/home/mike/.cache' \
        ::"llama-local-{now:%Y-%m-%d-%H%M%S}" \
        /home/mike/.ollama \
        /home/mike/Modelfile* \
        /var/lib/open-webui \
        /etc/ssh/ssh_host_ed25519_key; then

        echo "Pruning old local archives..."
        borg prune \
          --list \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6

        echo "Local backup succeeded."
        send_alert "info" "SUCCESS: Local backup completed on llama."
      else
        echo "Local backup failed!" >&2
        send_alert "error" "FAILED: Local backup on llama encountered errors."
        exit 1
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.borg-backup-llama-local = {
    description = "Automated Local Borg Backup for Llama Daily at 2:00 PM";
    timerConfig = {
      OnCalendar = "*-*-* 14:00:00";
      Persistent = true;
      Unit = "borg-backup-llama-local.service";
    };
    wantedBy = [ "timers.target" ];
  };

  # ---------------------------------------------------------------------------
  # 2. Remote Borg Backup Service & Timer (nixos-server)
  # ---------------------------------------------------------------------------
  systemd.services.borg-backup-llama = {
    description = "Automated Borg Backup for Llama State (Remote)";
    after = [ "network.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    path = with pkgs; [ borgbackup openssh iputils coreutils libnotify ];

    script = ''
      set -euo pipefail
      ${notifyLenovo}

      export BORG_PASSPHRASE="$(cat /run/secrets/borg_passphrase)"
      export BORG_REPO="ssh://root@nixos-server/var/lib/borg-llama"
      export BORG_RSH="ssh -i /etc/ssh/ssh_host_ed25519_key -o IdentitiesOnly=yes -o PreferredAuthentications=publickey"

      if ! ping -c 1 -W 5 nixos-server &>/devnull; then
        echo "nixos-server unreachable. Skipping remote backup." >&2
        send_alert "error" "WARNING: nixos-server unreachable. Remote backup skipped."
        exit 0
      fi

      echo "Starting llama state backup to nixos-server..."
      if borg create \
        --stats \
        --compression zstd \
        --exclude '/home/mike/.ollama/models/blobs' \
        --exclude '/home/mike/.cache' \
        ::"llama-{now:%Y-%m-%d-%H%M%S}" \
        /home/mike/.ollama \
        /home/mike/Modelfile* \
        /var/lib/open-webui \
        /etc/ssh/ssh_host_ed25519_key; then

        echo "Pruning old remote archives on nixos-server..."
        borg prune \
          --list \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6

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

  systemd.timers.borg-backup-llama = {
    description = "Automated Remote Borg Backup for Llama Daily at 2:30 PM";
    timerConfig = {
      OnCalendar = "*-*-* 14:30:00";
      Persistent = true;
      Unit = "borg-backup-llama.service";
    };
    wantedBy = [ "timers.target" ];
  };
}
