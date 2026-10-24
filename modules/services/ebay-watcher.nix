{ config, pkgs, lib, ... }:

let
  cfg = config.services.ebay-watcher;

  # Create a custom Python environment containing the required packages
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    requests
    beautifulsoup4
    curl-cffi
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
      default = 800;
    };

    maxPrice = lib.mkOption {
      type = lib.types.int;
      default = 1500; # Temporarily widened for testing
    };

    ntfyTopic = lib.mkOption {
      type = lib.types.str;
      default = "mike_3090_alerts";
    };

    pollInterval = lib.mkOption {
       type = lib.types.int;
      default = 180;
     };

    excludeWords = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "dell" "hp" "alienware" "omen" "waterblock" "block" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Expose 'ebay-admin' directly in your system PATH
    
   environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "ebay-admin";
      runtimeInputs = [ pkgs.git pkgs.gnused pkgs.systemd pythonEnv ];
      text = builtins.readFile ../scripts/ebay-admin.sh;
    })
  ];

    systemd.services.ebay-watcher = {
      description = "eBay Monitor Daemon";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        SEARCH_QUERY = cfg.searchQuery;
        MIN_PRICE = toString cfg.minPrice;
        MAX_PRICE = toString cfg.maxPrice;
        NTFY_TOPIC = cfg.ntfyTopic;
        POLL_INTERVAL = toString cfg.pollInterval;
      };

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "15s";
      };

      script = ''
        exec ${pythonEnv}/bin/python3 -u ${./ebay_watcher.py}
      '';
    };
  };

}
