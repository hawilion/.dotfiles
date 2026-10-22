{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/syncthing.nix
    ../../modules/scripts.nix
    ../../modules/borg-backup-lenovo.nix
    ../../modules/services/ebay-watcher.nix
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
  # In your hosts/lenovo/default.nix (or a desktop services file)

  systemd.user.services.ntfy-desktop-listener = {
    description = "Ntfy Desktop Notification Listener";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "ntfy-listener" ''
        set +e
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        export WAYLAND_DISPLAY="wayland-0"
        
        while true; do
          ${pkgs.curl}/bin/curl -sN "https://ntfy.sh/mike_3090_alerts/json" | while read -r line; do
            [ -z "$line" ] && continue
            event=$(${pkgs.jq}/bin/jq -r '.event // empty' <<< "$line" 2>/dev/null)
            if [ "$event" = "message" ]; then
              title=$(${pkgs.jq}/bin/jq -r '.title // "eBay Alert"' <<< "$line" 2>/dev/null)
              message=$(${pkgs.jq}/bin/jq -r '.message // "New update"' <<< "$line" 2>/dev/null)
              ${pkgs.libnotify}/bin/notify-send -u critical -r 999 "$title" "$message"
            fi
          done
          sleep 5
        done
      '';
      Restart = "always";
      RestartSec = "10s";
    };
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
  services.ebay-watcher = {
    enable = true;
    maxPrice = 1500; # Keep widened for your test window
    minPrice = 800;
  };
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
    libreoffice-qt6-fresh
    libnotify
    ntfy
  ];

  system.stateVersion = "24.11";
}
