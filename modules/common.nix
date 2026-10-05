{ config, pkgs, ... }:

{
  time.timeZone = "Pacific/Honolulu";
  networking.hosts = {
  "192.168.79.86" = [ "llama" ];
  "192.168.79.99" = [ "lenovo" ];
  };    
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
networking.hosts = {
  "127.0.0.1" = [ "localhost" ];
  "192.168.79.72" = [ "nixos-server" ];
  "192.168.79.86" = [ "llama" ];
  "192.168.79.99" = [ "lenovo" ];
};
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "07:15";
    options = "-d";
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings.PasswordAuthentication = true;
  };


  # Centralized systemd-resolved DNS configuration
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        MulticastDNS = "yes";
        FallbackDNS = "8.8.8.8";
      };
    };
  };


  # Shared Desktop Environment (KDE Plasma 6 + SDDM)
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

  # Shared Audio (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.sudo = {
  enable = true;
  extraConfig = ''
    Defaults timestamp_timeout=30
  '';
}; 
 services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Hardware & System Features
  hardware.bluetooth.enable = true;
  services.flatpak.enable = true;

  environment.shellAliases = {
    nrlenovo = "$HOME/.dotfiles/modules/scripts/rebuild-lenovo.sh";
    nrllama  = "$HOME/.dotfiles/modules/scripts/rebuild-llama.sh";
  };
 
 environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    sops
    age
    tree
    plocate
    brave
    ripgrep
dnsutils #neetwork tools
iputils
tcpdump
nmap
curl 
netcat
iperf3
mtr
openssl
traceroute
netcat

  ];

  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };
}
