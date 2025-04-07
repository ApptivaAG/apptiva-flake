{
  lib,
  self',
  config,
  apptiva-lib,
  ...
}:
let
  rootConfig = config;
in
{
  imports = [
    ./kubernetes
    ./container.nix
    ./dev-shell.nix
  ];
  perSystem =
    {
      pkgs,
      system,
      config,
      ...
    }:
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
                inherit
                  pkgs
                  system
                  rootConfig
                  apptiva-lib
                  ;
                systemConfig = config;
              };
            }
          );
        };
        targetConfigurations = lib.mkOption {
          type = lib.types.anything;
          default = lib.mapAttrs (name: value: value.configuration) config.targets;
        };
        targetConfigurationsFile = lib.mkOption {
          type = lib.types.package;
          default = pkgs.writeText "target-configurations.json" (builtins.toJSON config.targetConfigurations);
        };
        substitute-secrets = lib.mkOption {
          type = lib.types.package;
          default = pkgs.writeShellApplication {
            name = "substitute-secrets";
            runtimeInputs = [
              pkgs.vals
            ];
            text = ''
              vals eval -f - -o json
            '';
          };
        };
      };
      config = {
        packages = lib.mergeAttrsList (
          lib.mapAttrsToList (
            targetName: targetConfig:
            lib.mapAttrs' (name: package: {
              name = "${targetName}-${name}";
              value = package;
            }) targetConfig.packages
          ) config.targets
        );
        targets.local = { };
      };
    };
}
