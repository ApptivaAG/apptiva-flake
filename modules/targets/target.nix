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
  targetConfig = config;
  environmentType = lib.types.attrsOf (
    lib.types.submodule (
      { config, name, ... }:
      {
        options = {
          value = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = if config.secret != null then "ref+sops://${targetConfig.secretsFile}#${name}" else null;
          };
          secret = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          command = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      }
    )
  );
  buildEnvironment = environment: {
    values = lib.mapAttrs (key: value: value.value) (
      lib.filterAttrs (key: value: value.value != null) environment
    );
    script =
      let
        commandEnvironments = lib.filterAttrs (key: value: value.command != null) environment;
        commands = lib.mapAttrs (key: value: ''export ${key}="${value.command}"'') commandEnvironments;
      in
      lib.concatLines (lib.attrValues commands);
  };
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
    buildEnvironment = lib.mkOption {
      type = environmentType;
      default = { };
    };
    runtimeEnvironment = lib.mkOption {
      type = environmentType;
      default = { };
    };
    deployCommand = lib.mkOption {
      type = lib.types.str;
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
    secretsFile = lib.mkOption {
      type = lib.types.path;
    };
    configuration = lib.mkOption {
      type = json;
      default = {
        environment.runtime = buildEnvironment config.runtimeEnvironment;
        environment.build = buildEnvironment config.buildEnvironment;
        deployCommand = "${config.deployCommand}";
      };
    };
  };
}
