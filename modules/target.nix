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
  };
}
