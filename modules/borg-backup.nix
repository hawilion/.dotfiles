{ config, pkgs, lib, ... }:

let
  borgBackupScript  = pkgs.writeShellScriptBin "borg-run" (builtins.readFile ./scripts/borg-run.sh);
  borgJournalScript = pkgs.writeShellScriptBin "borg-journal" (builtins.readFile ./scripts/borg-journal.sh);
in
{
  environment.systemPackages = [
    borgBackupScript
    borgJournalScript
  ];

  # Automated Systemd Backup Service
  systemd.services.borg-backup-lenovo = {
    description = "Automated Borg Backup for Lenovo";
    after = [ "network.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    
    # Provide required binaries to systemd execution path
    path = with pkgs; [
      borgbackup
      libnotify
      iputils    # ping
      coreutils  # cat, echo, sleep
    ];

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
