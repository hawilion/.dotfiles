{ config, pkgs, lib, ... }:

let
  secrets = import ./secrets/syncthing-secrets.yaml;
in

{
  # Allow Syncthing ports through the firewall
  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];

  # Ensure directories exist and have correct permissions
  systemd.tmpfiles.rules = [
    "d /home/mike/.local/state/syncthing 0700 mike users -"
    "d /home/mike/.config/syncthing 0700 mike users -"
    "d /home/mike/.keys/syncthing-nixos 0700 mike users -"
  ];

  # User group configuration
  users.users.mike = {
    extraGroups = [ "users" ];
  };

  # Syncthing configuration
  services.syncthing = {
    enable = true;
    group = "users";
    user = "mike";
    openDefaultPorts = true;
    configDir = "/home/mike/.config/syncthing";
    dataDir = "/home/mike/.local/state/syncthing";
    key = "/home/mike/.keys/syncthing-nixos/key.pem";
    cert = "/home/mike/.keys/syncthing-nixos/cert.pem";
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      databaseTuning = "small";
      maxFolderConcurrency = 1;
      maxConcurrentIncomingRequestKiB = 32768;

      gui = {
        address = "0.0.0.0:8384";
        enabled = true;
        theme = "dark";
        user = "mike";
        password = secrets.syncthing_gui_password;
      };

      devices = {
        "nixos" = {
          id = "APIGR7E-YKYSK7J-4DPDUFN-K74A6KL-W4KBFHL-N26623I-LQMG3ZE-KASQ7QS";
        };
        "pixel6" = {
          id = "5O4BIQZ-HVHVNSV-5T2PYVH-7DY4MIL-VJHD7N6-LQEBGGU-MUSSNPL-NKHLOAF";
        };
        "nixos-server" = {
          id = "XEFJCKE-E6PM5UR-C25S7ZZ-YUK2G3C-DPEFCNO-QY7SREW-5O5Z5RJ-L26KSQC";
        };
      };

      folders = {
        "mlog" = {
          id = "ksov6-obsn7";
          path = "/home/mike/mlog";
          devices = [
            "pixel6"
            "nixos-server"
          ];
        };
        "Camera" = {
          id = "nuz3y-otvkt";
          path = "/home/mike/Camera";
          devices = [
            "pixel6"
            "nixos-server"
          ];
          ignorePerms = false;
        };
      };
    };
  };

  # Systemd service environment variables
  systemd.services.syncthing.environment = {
    STNODEFAULTFOLDER = "true";
  };
}
