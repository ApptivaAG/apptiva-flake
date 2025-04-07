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
          secrets.secretsFile = "../secrets.yaml";
          allTargets = {
            runtimeEnvironment = {
              FOO = "1";
              SECRET_FOO = config.secrets.getSecret "SECRET_FOO";
            };
            kubernetes = {
              cpu = {
                limit = "100m";
                request = "100m";
              };
              memory = {
                limit = "100Mi";
                request = "100Mi";
              };
              kubeconfigFile = "";
            };
          };
          targets.prod = {
            kubernetes = {
              enable = true;
            };
            container.streamLayeredImage = pkgs.dockerTools.streamLayeredImage {
              name = "container";
              config.Cmd = [
                "${pkgs.nodejs}/bin/node"
                "--eval"
                "require('http').createServer((req,res)=>res.end('hello apptiva!')).listen(80)"
              ];
            };
          };
        };
    });
}
