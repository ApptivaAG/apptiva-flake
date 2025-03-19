{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    apptiva-flake.url = "github:apptivaag/apptiva-flake";
  };

  outputs =
    inputs:
    inputs.apptiva-flake.lib.mkFlake { inherit inputs; } ({
      appName = "example-app";

      perSystem =
        { pkgs, config, ... }:
        {
          devDependencies = [
            pkgs.nodejs
            pkgs.sops
          ];
          secrets.secretsFile = ./secrets.yaml;
          allTargets = {
            runtimeEnvironment = {
              FOO = "1";
              SECRET_FOO = config.secrets.getSecret "SECRET_FOO";
            };
            kubernetes = {
              image = "nginx";
              cpu = {
                limit = "100m";
                request = "100m";
              };
              memory = {
                limit = "100Mi";
                request = "100Mi";
              };
            };
          };
          targets.prod = {
            kubernetes = {
              enable = true;
            };
          };
        };
    });
}
