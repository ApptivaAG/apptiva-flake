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
  perSystem =
    { pkgs, config, ... }:
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
                appName = rootConfig.appName;
              };
            }
          );
        };
      };
      config =
        let
          allEnvironments = pkgs.writeText "environments.json" (
            builtins.toJSON (lib.mapAttrs (name: value: value.environment) config.targets)
          );
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
          packages.target-environment-json = pkgs.writeShellApplication {
            name = "target-environment-json";
            runtimeInputs = [
              pkgs.jq
              pkgs.vals
            ];
            text = ''
              jq ".$1" < ${allEnvironments} | vals eval -f - -o json
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
