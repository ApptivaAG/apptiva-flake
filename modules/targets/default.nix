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
    ./container.nix
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
          packages.get-target-value = pkgs.writeShellApplication {
            name = "get-target-value";
            runtimeInputs = [
              pkgs.jq
            ];
            text = ''
              jq -r ".$TARGET.$1" < "$TARGET_CONFIGURATIONS"
            '';
          };
          packages.target-environment-json = pkgs.writeShellApplication {
            name = "target-environment-json";
            runtimeInputs = [
              config.packages.get-target-value
            ];
            text = ''
              get-target-value environment
            '';
          };
          packages.target-environment-exports = pkgs.writeShellApplication {
            name = "target-environment-exports";
            runtimeInputs = [
              config.packages.get-target-value
              config.substitute-secrets
              json-to-exports
            ];
            text = ''
              get-target-value "environment.$1.values" | substitute-secrets | json-to-exports
              get-target-value "environment.$1.script"
            '';
          };
          devDependencies = [
            config.packages.get-target-value
            config.packages.target-environment-exports
          ];
          shellHook = ''
            export TARGET_CONFIGURATIONS=${config.targetConfigurationsFile}
            export TARGET=''${TARGET:-local}
            source <(target-environment-exports runtime)
            source <(target-environment-exports build)
          '';
        };
    };
}
