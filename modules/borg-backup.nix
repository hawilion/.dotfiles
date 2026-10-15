{ config, pkgs, lib, ... }:

let
  # ... existing script definitions ...
in
{
  # ... existing systemPackages and lenovo configuration ...

  # Systemd Borg Backup service for llama targeting nixos-server
  systemd.services.borg-backup-llama = lib.mkIf (config.networking.hostName == "llama") {
    description = "Automated Borg Backup for Llama State";
    after = [ "network.target" "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    path = with pkgs; [ borgbackup openssh iputils coreutils libnotify ];

    script = ''
      set -euo pipefail
      export BORG_PASSPHRASE="$(cat /run/secrets/borg_passphrase)"
      export BORG_REPO="ssh://nixos-server/var/lib/borg-llama"

      # Ping check for connectivity
      if ! ping -c 1 -W 5 nixos-server &>/dev/null; then
        echo "nixos-server unreachable. Skipping backup." >&2
        exit 0
      fi

      echo "Starting llama state backup to nixos-server..."
      borg create \
        --stats \
        --compression zstd \
        --exclude '/home/mike/.ollama/models/blobs' \
        --exclude '/home/mike/.cache' \
        ::"llama-{now:%Y-%m-%d-%H%M%S}" \
        /home/mike/.ollama \
        /home/mike/Modelfile* \
        /var/lib/open-webui \
        /etc/ssh/ssh_host_ed25519_key

      echo "Backup to nixos-server succeeded."
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root"; # Run as root to back up /var/lib/open-webui and host SSH keys
    };
  };

  # Daily 2:30 PM Automated Timer for Llama
  systemd.timers.borg-backup-llama = lib.mkIf (config.networking.hostName == "llama") {
    description = "Automated Borg Backup for Llama Daily at 2:30 PM";
    timerConfig = {
      OnCalendar = "*-*-* 14:30:00";
      Persistent = true;
      Unit = "borg-backup-llama.service";
    };
    wantedBy = [ "timers.target" ];
  };
}
