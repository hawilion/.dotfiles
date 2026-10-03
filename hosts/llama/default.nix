{ config, pkgs, inputs, ... }:

{
  assertions = [
    {
      assertion = config.networking.hostName == "llama";
      message = "Error: You are attempting to build the 'llama' profile on a host that is not named 'llama'!";
    }
  ];

  security.sudo.extraRules = [
  {
    users = [ "mike" ];
    commands = [
      {
        command = "ALL";
        options = [ "NOPASSWD" ];
      }
    ];
  }
];

  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/syncthing.nix
    ../../modules/scripts.nix
  ];
  
  nix.settings.trusted-users = [ "root" "mike" ];

  networking.hostName = "llama";
  networking.networkmanager.enable = true;
  networking.hosts = {
    "127.0.0.1" = [ "localhost" ];
    "192.168.79.72" = [ "nixos-server" ];
    "192.168.79.99" = [ "lenovo" ];
  };

  # SOPS-Nix secrets for llama server
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

  # Network Discovery
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

  services.open-webui = {
  enable = true;
  port = 8080;
  host = "0.0.0.0";
  environment = {
    OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    WEBUI_URL = "http://192.168.79.86:8080";
    ENABLE_OLLAMA_API = "True";
  };
};

networking.firewall.allowedTCPPorts = [ 11434 8080 ];


  # Headless NVIDIA driver configuration for Ollama / local inference
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
  };

  # Ollama AI Service with CUDA acceleration
   
  # hosts/llama/default.nix
services.ollama = {
  enable = true;
  package = pkgs.ollama; # Fast CPU binary until 3090 is seated
  host = "0.0.0.0";
  port = 11434;
 #acceleration = "cuda";
  environmentVariables = {
    OLLAMA_HOST = "0.0.0.0:11434";
    OLLAMA_ORIGINS = "*";
  };
};
systemd.services.ollama.environment = {
  OLLAMA_HOST = "0.0.0.0:11434";
  OLLAMA_ORIGINS = "*";
};


  # User Account & Secure Password Hash Configuration
  users.users.mike = {
    isNormalUser = true;
    description = "Mike Lillie";
    home = "/home/mike";
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
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
    ollama-cuda
  ];

  system.stateVersion = "24.11";
}
