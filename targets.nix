{ lib, config, ... }:
{
  options = {
    allTargets = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
    };
    targets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = [
            ./target.nix
            config.allTargets
          ];
          specialArgs = {
            appName = config.appName;
          };
        }
      );
    };
  };
}
