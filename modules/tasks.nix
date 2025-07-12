{ config, pkgs, lib, ... }:

let
  syncScript = pkgs.writeScript "sync-script.sh" ''
    #!/bin/bash
    set -e
    echo "Backing up /etc/nixos..."
    git -C /etc/nixos add .
    git -C /etc/nixos commit -m "Auto-backup at $(date)"
  '';
in

{
  systemd.services.backup-etc-nixos-laptop = {
    description = "Backup /etc/nixos";
    serviceConfig = {
      Type = "oneshot";
      User = "mike";
      ExecStart = "${syncScript}/sync-script.sh";
      ProtectSystem = "full";
      ProtectHome = true;
      NoNewPrivileges = true;
    };
    path = [ pkgs.bash ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.timers.backup-etc-nixos-laptop = {
    timerConfig = {
      OnCalendar = "*-*-* 20:00:00";
      Persistent = true;
      Unit = "backup-etc-nixos-laptop";
    };
    wantedBy = [ "timers.target" ];
  };
}
