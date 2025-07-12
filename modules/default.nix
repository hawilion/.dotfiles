{
  description = "My Dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = self.packages.x86_64-linux.my-config;

    packages.x86_64-linux.my-config = import ./nix/config.nix;
  };
}
