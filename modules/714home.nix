{ config, pkgs, lib, ... }:

{
  # Required: Set username and home directory
  home.username = "mike";
  home.homeDirectory = "/home/mike";
  home.stateVersion = "24.11"; # Match your HM version

  # Example configuration for X resources (e.g., cursor size and DPI for a 4K monitor)
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  # Install packages in user profile
  home.packages = with pkgs; [
    zsh
    git
    brave
    audacity
    localsend
  ];

  # Enable and configure Zsh
  programs.zsh = {
    enable = true;
    zshrc = ''
      # Custom zshrc content
    '';
  };

  # Enable KDE Connect
  programs.kdeconnect.enable = true;

  # Enable Git with aliases and user info
  programs.git = {
    enable = true;
    userName = "Mike Lillie";
    userEmail = "mlillie57@gmail.com";
    aliases = {
      ci = "commit";
      co = "checkout";
      s = "status";
    };
    extraConfig = {
      alias.myalias = "some-command";
    };
  };

  # Optional: Enable Bash (and optionally manage .bashrc)
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';
  };

  # Optional: Set session environment variables
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Optional: Let Home Manager manage itself
  programs.home-manager.enable = true;
}
