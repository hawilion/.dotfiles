{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # SOPS-Nix configuration
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
    # Declare secrets to provision in /run/secrets/
    secrets."syncthing-gui-password" = {
      owner = "mike";
    };
    secrets."borg_passphrase" = {
      owner = "mike";
    };
  };

  # Hostname & Networking
  networking = {
    hostName = "lenovo";
    networkmanager.enable = true;
    hosts = {
      "127.0.0.1" = [ "localhost" ];
      "192.168.79.72" = [ "nixos-server" ];
    };
  };

  systemd.tmpfiles.rules = [
    "f /var/log/sync-script.log 0644 root root - -"
  ];

  imports = [
    ./hardware-configuration.nix
    ./modules/syncthing.nix
#    ./modules/tasks.nix
    ./modules/simple-scan.nix
    ./modules/scripts.nix
  ];

  nix.gc = {
    automatic = true;
    dates = "07:15";
    options = "-d";
  };

  systemd.services.syncthing.environment = {
    "STNODEFAULTFOLDER" = "true";
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
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

  # Display and Desktop
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing & Scanning
  boot.kernelModules = [ "sg" ];
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      brlaser
      brgenml1lpr
      brgenml1cupswrapper
    ];
  };

  hardware.sane = {
    enable = true;
    brscan4.enable = true;
  };

  services.teamviewer.enable = true;
  services.flatpak.enable = true;
  hardware.bluetooth.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Consolidated User Account
  users.users.mike = {
    isNormalUser = true;
    description = "Mike Lillie";
    home = "/home/mike";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "scanner"
      "lp"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
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
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    neovim
    wget
    plocate
    gparted
    nmap
    gscan2pdf
    xsane
    anki-bin
    syncthing
    sops
    age
    git
    go
    tree
  ];

  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  system.stateVersion = "24.11";

  services.resolved = {
  enable = true;
  fallbackDns = [ "8.8.8.8" "2001:4860:4860::8844" ];
  extraConfig = ''
    MulticastDNS=yes
  '';
 };  
}
