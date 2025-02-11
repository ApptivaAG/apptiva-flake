{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    apptiva-flake.url = "github:apptivaag/apptiva-flake";
  };

  outputs =
    inputs:
    inputs.apptiva-flake.lib.mkFlake { inherit inputs; } ({
      appName = "apptiva-flake";
      perSystem =
        { pkgs, ... }:
        {
          devDependencies = [ pkgs.nodejs ];
          targets.local.environment = {
            FOO = "BAR";
          };
        };
    });
}
