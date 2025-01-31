{
  lib,
  ...
}:
{
  options = {
    appName = lib.mkOption {
      type = lib.types.str;
    };
  };
}
