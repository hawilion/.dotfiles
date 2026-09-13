{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/syncthing.nix
    ../../modules/simple-scan.nix
    ../../modules/scripts.nix
  ];

  networking.hostName = "lenovo";
  networking.networkmanager.enable = true;
  networking.hosts = {
    "127.0.0.1" = [ "localhost" ];
    "192.168.79.72" = [ "nixos-server" ];
  };

  # SOPS-Nix secrets for laptop
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

  # Network Discovery & Printing/Scanning
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

  services.printing = {
    enable = true;
    drivers = with pkgs; [ brlaser brgenml1lpr brgenml1cupswrapper ];
  };

  hardware.sane = {
    enable = true;
    brscan4.enable = true;
  };

  services.teamviewer.enable = true;

  # Enable graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
};
  # Enable plasma 6 and sddm display
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  # User Account & Laptop Packages

  users.users.mike = {
    isNormalUser = true;
    description = "Mike Lillie";
    home = "/home/mike";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "scanner" "lp" ];
    packages = with pkgs; [ kdePackages.kate ];
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

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    gparted
    nmap
    gscan2pdf
    xsane
    anki-bin
    syncthing
    go
  ];

  system.stateVersion = "24.11";
}
