{ config, ... }:
let
  rootConfig = config;
in
{
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      shells = lib.mapAttrs (
        name: target:
        pkgs.mkShell {
          buildInputs = config.buildDependencies ++ config.runtimeDependencies ++ config.devDependencies;
          shellHook = ''
            ${config.shellHook}
            ${target.shellHook}
          '';
        }
      ) config.targets;
    in
    {
      options.shellHook = lib.mkOption {
        type = lib.types.lines;
        default = ''echo "Hello $(whoami), welcome to ${rootConfig.appName}!"'';
      };
      config.devShells = shells // {
        default = config.devShells.local;
      };
    };
}
