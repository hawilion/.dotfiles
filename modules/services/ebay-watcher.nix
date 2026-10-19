{ config, pkgs, lib, ... }:

let
  cfg = config.services.ebay-watcher;

  # Create a custom Python environment containing the required packages
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    requests
    beautifulsoup4
  ]);
in
{
  options.services.ebay-watcher = {
    enable = lib.mkEnableOption "eBay RTX 3090 Monitor Service";

    searchQuery = lib.mkOption {
      type = lib.types.str;
      default = "RTX 3090";
    };

    minPrice = lib.mkOption {
      type = lib.types.int;
      default = 900;
    };

    maxPrice = lib.mkOption {
      type = lib.types.int;
      default = 1150;
    };

    ntfyTopic = lib.mkOption {
      type = lib.types.str;
      default = "mike_3090_alerts";
    };

    excludeWords = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "dell" "hp" "alienware" "omen" "waterblock" "block" ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ebay-watcher = {
      description = "eBay Monitor Daemon";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "15s";
        Environment = [
          "SEARCH_QUERY=${cfg.searchQuery}"
          "MIN_PRICE=${toString cfg.minPrice}"
          "MAX_PRICE=${toString cfg.maxPrice}"
          "NTFY_TOPIC=${cfg.ntfyTopic}"
        ];
      };

      # Use the custom python environment binary directly
      script = ''
        exec ${pythonEnv}/bin/python3 ${./ebay_watcher.py}
      '';
    };
  };
}
