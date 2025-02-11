{
  name,
  lib,
  appName,
  ...
}:
{
  options = {
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "${appName}-${name}.apps.apptiva.ch";
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
}
