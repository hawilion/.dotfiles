{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

     home-manager = {
       url = "github:nix-community/home-manager";
       inputs.nixpkgs.follows = "nixpkgs";
     };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Use `specialArgs` instead of `extraSpecialArgs`
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
         inputs.home-manager.nixosModules.default
         {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mike = import ./home.nix;
          }
      ];
    };
  };
}
