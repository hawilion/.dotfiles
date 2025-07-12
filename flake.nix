{
  description = "My NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix, home-manager }:
    let
      system = "x86_64-linux";

      # 👇 Define modules inside the `let` block
      modules = {
        default = ./modules/default.nix;
        secrets = ./modules/secrets.nix;
      };
    in
    {
      # 👇 Expose modules (optional)
      modules = modules;

      # 👇 NixOS configuration
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          modules.default
          modules.secrets
          ./configuration.nix
          sops-nix.nixosModules.default
          home-manager.nixosModules.home-manager
          ./modules/home.nix
        ];
      };

      # 👇 Optional: Home Manager configurations
      homeConfigurations = {
        mike = home-manager.lib.homeConfigurations."${system}" {
          username = "mike";
          modules = [
            ./home/mike
          ];
        };
      };
    };
}

