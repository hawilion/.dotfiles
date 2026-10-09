{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/syncthing.nix
    ../../modules/scripts.nix
    ../../modules/borg-backup.nix

  ];
    
  nix.settings.trusted-users = [ "root" "mike" ];

  networking.hostName = "lenovo";
  networking.networkmanager.enable = true;

  # Host-level Tailscale & systemd-resolved
  services.tailscale.enable = true;

  # SOPS-Nix secrets configuration
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
    secrets."syncthing-gui-password" = { owner = "mike"; };
    secrets."borg_passphrase" = { owner = "mike"; };
  };

  systemd.tmpfiles.rules = [
    "f /var/log/sync-script.log 0644 root root - -"
  ];

  systemd.services.syncthing.environment = {
    "STNODEFAULTFOLDER" = "true";
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "sg" ];

  # Printing & Network Discovery
  

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  # Declarative Printer Queue via Static Socket
  # Declarative Printer Queue via Static Socket
  hardware.printers = {
  ensurePrinters = [
    {
      name = "Brother_MFC_L2710DW";
      deviceUri = "ipp://192.168.79.190/ipp/print";
      model = "everywhere";
    }
  ];
  ensureDefaultPrinter = "Brother_MFC_L2710DW";
};

  # Built-in SANE Scanner Configuration
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.brscan4 ];
  };

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
    nssmdns4 = true;
    openFirewall = true;
  };

  services.teamviewer.enable = true;

  # User Account Configuration
  users.users.mike = {
    isNormalUser = true;
    description = "Mike Lillie";
    home = "/home/mike";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "scanner" "lp" ];
    hashedPassword = "$6$akZ5eCOKYl7/EMxe$wwBHra3bZyzFfdcyknWx5hoIvoa/gOnBcdqWJHjvqfTwMTwr2n9KiI.vw55ZBWPwgUSv6j265crG2DeYL00DJ1";
  };

  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host nixos-server
        HostName 192.168.79.72
        User mike
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  environment.systemPackages = with pkgs; [
    nmap
    syncthing
    go
  ];

  system.stateVersion = "24.11";
}
