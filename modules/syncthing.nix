{ config, pkgs, lib, ... }:

{
  # Point sops to your secrets file relative to this module
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  # Declare the secret so sops-nix decrypts it
  sops.secrets."syncthing-gui-password" = {
    owner = "mike";
  };

  # Ensure directories exist and have correct permissions
  systemd.tmpfiles.rules = [
    "d /home/mike/.local/state/syncthing 0700 mike users -"
    "d /home/mike/.config/syncthing 0700 mike users -"
  ];

  # User group configuration
  users.users.mike = {
    extraGroups = [ "users" ];
  };

  # Syncthing configuration
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    group = "users";
    user = "mike";
    openDefaultPorts = true;
    configDir = "/home/mike/.config/syncthing";
    dataDir = "/home/mike/.local/state/syncthing";
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      databaseTuning = "small";
      maxFolderConcurrency = 1;
      maxConcurrentIncomingRequestKiB = 32768;
      options = {
        localAnnounceEnabled = true;
        localAnnouncePort = 21027;
        globalAnnounceEnabled = true;
  };
      gui = {
        address = "0.0.0.0:8384";
        enabled = true;
        theme = "dark";
        user = "mike";
        passwordFile = config.sops.secrets."syncthing-gui-password".path;
      };

      devices = {
        "lenovo" = {
          id = "T4PRAF6-IPACD6V-MYI5HBR-KYLQB4W-OKAEPW3-BL2JZH2-FRHLNUQ-L5VL2QH";
          addresses = [ "tcp://100.97.213.119:22000" ]; # Replace with lenovo'  Tailscale IP or tailnet hostname
        };
        "pixel10" = {
          id = "HEBRQRF-QMGQJBZ-SPDHEIU-VIN7DPW-OJFE5KM-JJRQYML-I5JA4GG-5IFXDQM";
          addresses = [ "tcp://100.72.222.102:22000" ]; # Replace with lenovo'  Tailscale IP or tailnet hostname
       };
      };

      folders = {
        "mlog" = {
          id = "ksov6-obsn7";
          path = "/home/mike/mlog";
          devices = [ "lenovo" "pixel10" ];
        };
        "Camera" = {
          id = "nuz3y-otvkt";
          path = "/home/mike/Camera";
          devices = [ "lenovo" "pixel10" ];
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
