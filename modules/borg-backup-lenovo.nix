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
        title="Lenovo Borg Backup FAILURE"
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
  systemd.services.borg-backup-lenovo = {
    description = "Automated Borg Backup for Lenovo (Remote to nixos-server)";
    after = [ "network.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    path = with pkgs; [ borgbackup openssh iputils coreutils curl ];

    script = ''
      set -euo pipefail
      ${sendAlert}

      export BORG_PASSPHRASE="$(cat /run/secrets/borg_passphrase)"
      export BORG_REPO="ssh://root@nixos-server/var/lib/borg-lenovo"
      export BORG_RSH="ssh -i /etc/ssh/ssh_host_ed25519_key -o IdentitiesOnly=yes -o PreferredAuthentications=publickey"

      set +e
      ping -c 1 -W 5 nixos-server &>/dev/null
      PING_STATUS=$?
      set -e

      if [ $PING_STATUS -ne 0 ]; then
        echo "nixos-server unreachable. Skipping remote backup." >&2
        send_alert "error" "WARNING: nixos-server unreachable. Lenovo backup skipped."
        exit 0
      fi

      echo "Starting lenovo backup to nixos-server..."
      if borg create \
        --stats \
        --compression zstd \
        --exclude '/home/mike/.cache' \
        ::"lenovo-{now:%Y-%m-%d-%H%M%S}" \
        /home/mike/Documents \
        /home/mike/.dotfiles; then

        echo "Pruning old archives on nixos-server..."
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
    description = "Automated Borg Backup for Lenovo Daily at 3:00 PM";
    timerConfig = {
      OnCalendar = "*-*-* 15:00:00";
      Persistent = true;
      Unit = "borg-backup-lenovo.service";
    };
    wantedBy = [ "timers.target" ];
  };
}
