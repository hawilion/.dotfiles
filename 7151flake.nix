{
  description = "NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, home-manager }:
    let
      system = "x86_64-linux";
      home = { config, pkgs, ... }:
        {
          home.username = "mike";
          home.homeDirectory = "/home/mike";
          home.stateVersion = "24.11";
          home.packages = with pkgs; [ vim git ];
        };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          sops-nix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.users.mike = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
              modules = [ home ];
            };
          }
        ];
      };
    };
}
