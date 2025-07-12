{ lib, config, pkgs, ... }:
let
  cfg=main-user;
in
{

 options = {
   main-user.enable=lib.MkEnableOption "enable user module";

   main-user.userName = lib.mkOption {
    default = "mainuser";
    description = ''
      username
      '';
   };
};

  config =lib.mkIf cfg.enable {   
    
    users.users.${config.username} = {
      isNormalUser = true;
      initialPassword = "12345";
      description = "main user";
      shell = pkgs.zsh;
   };
  };
}
