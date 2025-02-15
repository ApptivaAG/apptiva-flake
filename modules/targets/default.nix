{
  lib,
  self',
  config,
  ...
}:
let
  rootConfig = config;
in
{
  imports = [
    ./kubernetes
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
                inherit pkgs system rootConfig;
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
      config =
        let
          json-to-exports = pkgs.writeShellApplication {
            name = "json-to-exports";
            runtimeInputs = [
              pkgs.jq
            ];
            text = ''
              jq -r 'to_entries|map("export \(.key)=\(.value|tostring|@sh);")|.[]' <&0
            '';
          };
        in
        {
          packages.get-target-from-file = pkgs.writeShellApplication {
            name = "get-target-from-file";
            runtimeInputs = [
              pkgs.jq
            ];
            text = ''
              jq -r ".$2" < "$1"
            '';
          };
          packages.get-target = pkgs.writeShellApplication {
            name = "get-target";
            runtimeInputs = [
              config.packages.get-evaluated-target-from-file
              config.substitute-secrets
            ];
            text = ''
              get-evaluated-target-from-file ${config.targetConfigurationsFile} "$1" | substitute-secrets
            '';
          };
          packages.target-environment-json = pkgs.writeShellApplication {
            name = "target-environment-json";
            runtimeInputs = [
              config.packages.get-target
            ];
            text = ''
              get-target "$1.environment"
            '';
          };
          packages.target-environment-exports = pkgs.writeShellApplication {
            name = "target-environment-exports";
            runtimeInputs = [
              config.packages.target-environment-json
              json-to-exports
            ];
            text = ''
              target-environment-json "$1" | json-to-exports
            '';
          };
          devDependencies = [
            config.packages.target-environment-exports
          ];
          shellHook = ''
            export TARGET=''${TARGET:-local}
            source <(target-environment-exports $TARGET)
          '';
        };
    };
}
