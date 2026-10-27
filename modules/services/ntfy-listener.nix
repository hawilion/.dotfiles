{ config, pkgs, ... }:
let
  ntfyListenerScript = pkgs.writeShellScriptBin "ntfy-listener" ''
    #!/usr/bin/env bash
    TOPICS="mike-lenovo-borg-backups,mike-llama-borg-backups-96719"

    curl -sN "https://ntfy.sh/$TOPICS/json" | while read -r line; do
        if command -v jq &>/dev/null; then
            EVENT=$(echo "$line" | jq -r '.event // empty')
            if [ "$EVENT" = "message" ]; then
                TITLE=$(echo "$line" | jq -r '.title // "Borg Backup Notice"')
                MSG=$(echo "$line" | jq -r '.message // "No message provided"')
                PRIORITY=$(echo "$line" | jq -r '.priority // 3')
                
                if [ "$PRIORITY" -ge 4 ]; then
                    URGENCY="critical"
                else
                    URGENCY="normal"
                fi
                
                # -t 0 keeps the notification popup visible until manually dismissed
                notify-send -t 0 -u "$URGENCY" "$TITLE" "$MSG"
            fi
        fi
    done
  '';
in
{
  systemd.user.services.ntfy-listener = {
    description = "ntfy notification listener";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = with pkgs; [ curl jq libnotify coreutils bash ];
    serviceConfig = {
      ExecStart = "${ntfyListenerScript}/bin/ntfy-listener";
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
