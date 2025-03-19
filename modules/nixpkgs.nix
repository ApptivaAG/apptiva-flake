{
  lib,
  config,
  inputs,
  ...
}:
{
  options = {
    nixpkgs = {
      overlays = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ inputs.glueson.overlays.default ];
      };
    };
  };
  config = {
    perSystem =
      { system, ... }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = config.nixpkgs.overlays;
          config = {
            allowUnfree = true;
          };
        };
      };
  };
}
