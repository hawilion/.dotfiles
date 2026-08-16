# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  #Allow the 'root' user (or another user) to write to the log file
 systemd.tmpfiles.rules = [
    # Create /var/log/sync-script.log
    # Format: type path mode user group age command
    # Example: Create /var/log/sync-script.log with appropriate permission   
 "f /var/log/sync-script.log 0644 root root - -"
  ];

  imports =
    [
  ./hardware-configuration.nix
#  ./modules/main-user.nix
  inputs.home-manager.nixosModules.default
  #./modules/home.nix
  ./modules/syncthing.nix
  ./modules/tasks.nix
  ./modules/brscan4.nix
  ./modules/simple-scan.nix
    ];
 
#main-user.enable= true;
#main-user.userName= "mike";
 
nix.gc = {
   automatic = true; # Enable automatic garbage collection
   dates = "07:15"; # Run garbage collection daily at 7:15 AM
   options = "-d"; # Arguments passed to nix-collect-garbage
   };
  # Your other Nix configuration here

  systemd.services.syncthing.environment = {
    "STNODEFAULTFOLDER" = "true"; # Don't create default ~/Sync folder
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  # https://search.brave.com/search?q=getent+hosts+127.0.0.1+++++++localhost+127.0.0.1+++++++localhost+127.0.0.2+++++++nixos+192.168.79.72+++nixos-server+Avahi+cant+discover+nixos-werver&source=llmSuggest&summary=1&conversation=74b0e4aa0584b4a8a799d6

  networking = {
    networkmanager.enable = true;

    interfaces.enp0s25.ipv4.addresses = [
   {
        address = "192.168.79.80";
        prefixLength = 24;
      }
    ];
    #interfaces.enp0s25.useDHCP = false; 
    defaultGateway = "192.168.79.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    hostId = config.sops.secrets.networking.hostID;
    hostName = "nixos";
    domain = "local";

    hosts = {
      "127.0.0.1" = [ "localhost" ];
      "127.0.0.2" = [ "nixos" ];
      "192.168.79.72" = [ "nixos-server" ];
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

  services.resolved = {
    enable = true;
    fallbackDns = [
      "8.8.8.8"
      "2001:4860:4860::8844"
    ];
    extraConfig = ''
      MulticastDNS=yes
    '';
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Set your time zone.
  time.timeZone = "Pacific/Honolulu";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.  | https://search.brave.com/search?q=nixos+module+for+brother+mfc+2710+for+network+scanner+printer+is+working&source=web&tf=py&summary=1&conversation=2b07369b423d7361c0ab21
  boot.kernelModules = [ "sg" ];
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.brlaser
    pkgs.brgenml1lpr
    pkgs.brgenml1cupswrapper
  ];

  hardware.sane.enable = true;
  #enable teamviewer
  services.teamviewer.enable = true;
  #enable flatpak
  services.flatpak.enable = true;

  # backupLocation = "/path/to/backup";
  # // Add other configuration options as needed

  #services.printing.drivers = [ pkgs.brlaser ];
  #Enable bluetooth
  hardware.bluetooth.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mike = {
    isNormalUser = true;
    description = "Mike Lillie";
    home = "/home/mike";
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

  users.extraUsers.mike = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "scanner"
      "lp"
    ];
  };
  home-manager = {
    #also post inputs to home-manager modules
    #extraSpecialArgs = { inherit inputs; };
    users = {
      "mike" = import ./home.nix;
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with inputs.nixpkgs.pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.locate.enable = true;
  services.locate.package = pkgs.plocate;
  ### from https://discourse.nixos.org/t/syncthing-permission-denied/57272/2

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.AllowUsers = null; # Allows all users by default
  };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
