{ config, lib, pkgs, ... }:

{
  # Enable SANE support for scanning
  hardware.sane.enable = true;

  # Include extra backends if needed, e.g., for HP devices
  hardware.sane.extraBackends = [ pkgs.hplipWithPlugin ];

  # Ensure necessary Python packages are available
  environment.systemPackages = [
    pkgs.python27Packages.enum  # Example package, adjust based on specific needs
  ];

  # Additional configuration might be required based on specific scanner model
}
