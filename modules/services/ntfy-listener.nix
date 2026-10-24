{ pkgs, ... }:
{
  systemd.user.services.ntfy-listener = {
    description = "ntfy notification listener";
    wantedBy = [ "graphical-session.target" ];
    path = with pkgs; [ curl jq libnotify coreutils bash ];
    serviceConfig = {
      ExecStart = "${pkgs.callPackage ../scripts.nix {}.ntfyListenerScript}/bin/ntfy-listener";
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
