{
  perSystem.allTargets =
    {
      name,
      lib,
      config,
      ...
    }:
    {
      options.kubernetes = {
        enable = lib.mkEnableOption false;
        namespace = lib.mkOption {
          type = lib.types.str;
          default = "${config.appName}-${name}";
        };
      };
    };
}
