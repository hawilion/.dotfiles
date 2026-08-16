{ config, pkgs, lib, inputs, ... }:

{
  # Define the user and home directory
  users.users.sometestservice = {
    isSystemUser = true;
    home = "/var/lib/sometestservice";
    createHome = true;
    group = "sometestservice";
  };

  # Define secrets using sops-nix
  sops.secrets."myservice/my_subdir/my_secret" = {
    sopsFile = ./secrets/myservice/my_subdir/my_secret.txt;
    owner = "sometestservice";
    mode = "0600";
    neededForUsers = false;
    restartUnits = [ "sometestservice.service" ];
  };

  # Define systemd service using LoadCredential for secret injection
  systemd.services.sometestservice = {
    description = "Test service using sops-nix secret securely";

    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    requires = [ "sops-nix.service" ];

    serviceConfig = {
      Type = "simple";
      User = "sometestservice";
      WorkingDirectory = "/var/lib/sometestservice";

      # Use LoadCredential to inject secret securely
      LoadCredential = [
        "my_secret:${config.sops.secrets."myservice/my_subdir/my_secret".path}"
      ];

      # Access secret via environment variable
      Environment = "MY_SECRET_FILE=/run/credentials/sometestservice/my_secret";

      # Example command that uses the secret
      ExecStart = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."myservice/my_subdir/my_secret".path}";

      # Optional: clean up secrets after service stops
      UnsetCredentialOnExit = true;

      # Optional: ensure service restarts if secret changes
      Restart = "on-failure";
      RemainAfterExit = true;
    };
  };

  # Optional: symlink age key (if needed, but better managed via secrets)
  environment.etc."sops/age/keys.txt".source = "/home/mike/.config/sops/age/keys.txt";
}
