{ config, pkgs, inputs, lib, ... }:

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

  # --- 1. NVMe & Nix Store Optimization ---
  nix.settings.auto-optimise-store = true;
  nix.gc = lib.mkForce {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  services.fstrim.enable = true;

  networking.hostName = "llama";
  networking.networkmanager.enable = true;
  networking.hosts = {
    "127.0.0.1" = [ "localhost" ];
    "192.168.79.72" = [ "nixos-server" ];
    "192.168.79.99" = [ "lenovo" ];
  };

  # --- 2. Ollama Configuration (Keeps CUDA GPU acceleration) ---
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
    models = "/var/lib/ollama/models"; # Standard path on your nvme0n1 root disk
    environmentVariables = {
      OLLAMA_ORIGINS = "*";
      OLLAMA_KEEP_ALIVE = "10m"; # Drop model from VRAM/RAM after 10m idle
    };
  };

  # --- 3. Open WebUI Knowledge Base Interface ---
  services.open-webui = {
  enable = true;
  host = "0.0.0.0";
  port = 8080;
  openFirewall = true;
  environment = {
    WEBUI_HOST = "0.0.0.0";
    ENABLE_OLLAMA_API = "True";
    OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    OLLAMA_BASE_URLS = "http://127.0.0.1:11434";
    OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
    DATA_DIR = "/var/lib/open-webui/data";

    # RAG & Embedding configuration
    RAG_EMBEDDING_ENGINE = "ollama";
    RAG_OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    RAG_EMBEDDING_MODEL = "nomic-embed-text:latest";

    # Text chunking and splitting for Markdown/Logseq notes
    ENABLE_RAG_HYBRID_SEARCH = "True";
    ENABLE_RAG_LOCAL_WEB_FETCH = "True";
    CHUNK_SIZE = "1000";
    CHUNK_OVERLAP = "100";
    ENABLE_PERSISTENT_CONFIG = "False";
  };
};

  # SOPS-Nix secrets for llama server
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
      
    secrets."syncthing-gui-password" = { owner = "mike"; };
    secrets."borg_passphrase" = { owner = "mike"; };
  };

  # Directory permissions for Open WebUI and Ollama
  systemd.tmpfiles.rules = [
    "f /var/log/sync-script.log 0644 root root - -"
    "d /var/lib/ollama/models 0770 ollama ollama -"
    "d /var/lib/open-webui/data 0770 open-webui open-webui -"
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
  ];

  system.stateVersion = "24.11";
}
