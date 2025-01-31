{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      lib = import ./lib.nix { flake-parts = inputs.flake-parts; };
    in
    lib.mkFlake
      {
        inherit inputs;
      }
      {
        appName = "apptiva-flake";
        flake = {
          lib = lib;
          flakeModules.apptiva = import ./apptiva.nix;
        };
      };
}
