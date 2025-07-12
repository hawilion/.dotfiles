{
  description = "NixOS Config Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix, home-manager }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        "${self}/modules/default.nix"
        ./configuration.nix
        ./modules
        sops-nix.nixosModules.default
        home-manager.nixosModules.home-manager

        # Inline module for secrets
        {
          security.sops.secrets.secrets-yaml = {
            source = ./secrets/secrets.yaml;
            mode = "0600";
        };
       }

      ];
    };
  };
}
