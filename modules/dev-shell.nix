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
    {
      options.shellHook = lib.mkOption {
        type = lib.types.lines;
        default = ''echo "Hello $(whoami), welcome to ${rootConfig.appName}!"'';
      };
      config.devShells.default = pkgs.mkShell {
        buildInputs = config.buildDependencies ++ config.runtimeDependencies ++ config.devDependencies;
        shellHook = config.shellHook;
      };
    };
}
