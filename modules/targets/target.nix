{
  name,
  lib,
  config,
  pkgs,
  rootConfig,
  systemConfig,
  ...
}:
let
  json = import ../../json.nix { inherit lib; };
in
{
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = name;
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "${rootConfig.appName}-${name}.apps.apptiva.ch";
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
    deployCommand = lib.mkOption {
      type = lib.types.string;
      default =
        let
          package = pkgs.writeShellApplication {
            name = "no-deploy-command-configured";
            text = ''
              echo "No deploy command specified for target $1"
            '';
          };
        in
        "${package}/bin/no-deploy-command-configured";
    };
    configuration = lib.mkOption {
      type = json;
      default = {
        environment = config.environment;
        deployCommand = "${config.deployCommand}";
      };
    };
  };
}
