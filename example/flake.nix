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
        { pkgs, ... }:
        {
          devDependencies = [
            pkgs.nodejs
            pkgs.sops
          ];
          targets.local = {
            secretsFile = ./secrets.yaml;
            kubernetes = {
              enable = true;
              image = "nginx";
              namespace = "apptiva-flake-example";
              cpu = {
                limit = "100m";
                request = "100m";
              };
              memory = {
                limit = "100Mi";
                request = "100Mi";
              };
            };
            runtimeEnvironment = {
              FOO.value = "BAR";
              SECRET_FOO.secret = "SECRET_FOO";
              UGGA.command = "AGGA";
            };
          };
        };
    });
}
