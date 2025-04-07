{
  name,
  lib,
  apptiva-lib,
  config,
  pkgs,
  rootConfig,
  systemConfig,

  ...
}:
let
  environmentType = lib.types.attrsOf apptiva-lib.types.json;
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
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = name;
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "${rootConfig.appName}-${name}.apps.apptiva.ch";
    };
    devEnvironment = lib.mkOption {
      type = environmentType;
      default = { };
    };
    runtimeEnvironment = lib.mkOption {
      type = environmentType;
      default = { };
    };
    configuration = lib.mkOption {
      type = apptiva-lib.types.json;
      default = {
        deployCommand = "${config.deployCommand}";
      };
    };
    packages = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
    };
    shellHook = lib.mkOption {
      type = lib.types.lines;
      default = ''
        source <(${config.packages.print-environment}/bin/print-environment | ${json-to-exports}/bin/json-to-exports)
      '';
    };
  };
  config = {
    packages.print-environment = pkgs.writeGluesonApplication {
      name = "print-environment";
      value = config.devEnvironment // config.runtimeEnvironment;
    };
  };
}
