{
  description = "My NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";    
    home-manager = {
	url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
  };
 };
outputs = inputs@{ nixpkgs, home-manager, sops-nix, ... }: {
  nixosConfigurations = {
  nixos = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./configuration.nix
      ./modules/default.nix
      ./modules/secrets.nix
      ./modules/sops.nix

      # Home Manager integration
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.mike = import ./modules/home.nix;
# Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
      }

      # sops-nix module for secrets management
      sops-nix.nixosModules.sops
    ];
  };
 };
}

