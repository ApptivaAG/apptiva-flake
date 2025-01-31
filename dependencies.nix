{ lib, ... }:
{
  perSystem.options = {
    buildDependencies = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
    runtimeDependencies = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
    devDependencies = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };
}
