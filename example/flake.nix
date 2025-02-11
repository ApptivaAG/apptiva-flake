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
          targets.local.environment = {
            FOO = "BAR";
            SECRET_FOO = "ref+sops://example/secrets.yaml#SECRET_FOO";
          };
        };
    });
}
