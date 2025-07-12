{ config, pkgs, lib, ... }:

{
  security.sops.secrets.secrets-yaml = {
    source = ../../secrets/secrets.yaml;
    mode = "0600";
  };
}
