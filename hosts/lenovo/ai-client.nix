# hosts/lenovo/ai-client.nix
{ config, pkgs, ... }:

{
  # Local Open WebUI interface on Lenovo workstation
  services.open-webui = {
    enable = true;
    port = 8080;
    environment = {
      # Target the remote CPU/GPU inference host
      OLLAMA_BASE_URL = "http://192.168.79.86:11434";
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
    };
  };

  # Keep local port accessible if navigating from other browser windows
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
