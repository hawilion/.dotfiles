{config, pkgs, lib, ... }:

{
  home-manager.users.mike = {
    enable = true;
    homeDirectory = "/home/mike";
    packages = with pkgs; [ zsh ];
    programs = {
      zsh.enable = true;
      kdeconnect.enable = true;
   };
  };
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
   pkgs.brave
 # pkgs.anki-bin
   pkgs.audacity
   pkgs.localsend
  ];

  home.file = {
  home.sessionVariables = {
    # EDITOR = "emacs";
  };


  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
   programs.git = {
    enable = true;
    extraConfig = {
    alias.myalias = "some-command";
  };
    userName  = "mike";
    userEmail = "mlillie57@gmail.com";
    aliases = {
      ci = "commit";
      co = "checkout";
      s = "status";
    };
  };
 };
}

