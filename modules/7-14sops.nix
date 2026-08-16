
{ config, pkgs, lib, inputs, ... }:
let
   # aecess the nix-secrets input
  secretspath = builtins.toString inputs.nix-secrets; 
  # Helper to create a script that reads a secret at runtime
  makeSecretScript = secretPath: pkgs.writeShellScriptBin "read-secret.sh" ''
    #!/bin/sh
    set -e
    echo "Reading secret from: ${secretPath}"
    secret=$(cat "${secretPath}")
    echo "Secret value: \$secret" > /var/lib/sometestservice/testfile
  '';
in

{
  # Define user
  users.users.sometestservice = {
    isSystemUser = true;
    home = "/var/lib/sometestservice";
    createHome = true;
    group = "sometestservice";
  };

  # Systemd service using secret
  systemd.services.sometestservice = {
    description = "Test service reading secret";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple"; #"oneShot"
      RemainAfterExit = true;
      User = "sometestservice";
      WorkingDirectory = "/var/lib/sometestservice";
      ExecStart = makeSecretScript "${secretspath}/my-secret.txt";
    #  ExecStart = "${pkgs.writeShellScriptBin "read-secret" ''
    #    cat ${config.sops.secrets."myservice/my_subdir/my_secret".path} > /tmp/test-secret.txt
    #    chmod 600 /tmp/test-secret.txt
      ''}/bin/read-secret";
      # Use the wrapped script that has the secret baked in
      #ExecStart = "${makeSecretScript config.sops.secrets."myservice/my_subdir/my_secret".path}/bin/read-secret.sh ${config.sops.secrets."myservice/my_subdir/my_secret".path}";
      
      Wants = [ "sops-nix.service" ];
      After = [ "sops-nix.service" ];
    };
  };

  # Import sops-nix module settings
  imports = [
    # This assumes sops-nix is already available via flake input
    # and this module is used in a flake-based system
  ];

  # Symlink the private key to /etc (optional)
  environment.etc."sops/age/keys.txt".source = "/home/mike/.config/sops/age/keys.txt";

  # Main sops configuration
  sops = {
    # Default settings
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/mike/.config/sops/age/keys.txt"; # Private key for decryption
    defaultSopsFile = "${secretspath}/secrets.yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    age.generateKey = true;
    # Define your secrets
    secrets = {
      openai_api_key = { # sopsFile = ./secrets.yml.enc; # optionally define per-secret files
      path = "${config.sops.defaultSymlinkPath}/openai_api_key";
    };

      example-key = {
        sopsFile = ./secrets/modules/example-key.txt;
      };
      dade_passwd = {
        neededForUsers = true;
      };
       sops.secrets.my-secret = {
       file = ./secrets.yaml;
       neededForUsers = false;
      };
      "myservice/my_subdir/my_secret" = {
        sopsFile = "${secretspath}/secrets/myservice/my_subdir/my_secret.txt";
        owner = "sometestservice";
        neededForUsers = true;
      };
    };
  };
}
