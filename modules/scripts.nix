{ config, pkgs, lib, ... }:

let
  # Manual run script with libnotify desktop notifications
  nrfScript = pkgs.writeShellScriptBin "nrf" ''
  set -euo pipefail
  sudo nixos-rebuild switch --flake ~/.dotfiles#lenovo
'';
  borgBackupScript = pkgs.writeShellScriptBin "borg-run" ''
    set -euo pipefail
    export DISPLAY="''${DISPLAY:-:0}"
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"
    export BORG_PASSPHRASE=$(cat /run/secrets/borg_passphrase)
    # Target path or remote SSH repo location:
   export BORG_REPO="ssh://nixos-server/var/lib/borg-lenovo"
    echo "Starting Borg backup..."

    if ${pkgs.borgbackup}/bin/borg create \
      --stats \
      --compression zstd \
      --exclude '/home/mike/.cache' \
      --exclude '/home/mike/.nix-profile' \
      ::"lenovo-{now:%Y-%m-%d-%H%M%S}" \
      /home/mike/.dotfiles \
      /home/mike; then

      echo "Backup succeeded."
      ${pkgs.libnotify}/bin/notify-send -u normal -t 0  "Borg Backup" "Backup completed successfully!"
    else
      echo "Backup failed." >&2
      ${pkgs.libnotify}/bin/notify-send -u critical "Borg Backup" "Backup failed! Check journal logs using 'borg-journal'."
      exit 1
    fi
  '';

  # Command to immediately view logs if something goes wrong
  borgJournalScript = pkgs.writeShellScriptBin "borg-journal" ''
    exec ${pkgs.systemd}/bin/journalctl -u borg-backup-lenovo.service -e -f
  '';
in
{
  # Expose manual binaries to your user PATH
  environment.systemPackages = [
    borgBackupScript
    borgJournalScript
    nrfScript
  ];

  # Automated Systemd Backup Service
  systemd.services.borg-backup-lenovo = {
    description = "Automated Borg Backup for Lenovo";
    after = [ "network.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "mike";
      ExecStart = "${borgBackupScript}/bin/borg-run";
      Environment = [
        "DISPLAY=:0"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
    };
  };

  # Daily 2:00 PM Automated Timer (14:00:00)
  systemd.timers.borg-backup-lenovo = {
    description = "Automated Borg Backup Daily at 2:00 PM";
    timerConfig = {
      OnCalendar = "*-*-* 14:00:00";
      Persistent = true;
      Unit = "borg-backup-lenovo.service";
    };
    wantedBy = [ "timers.target" ];
  };
}
