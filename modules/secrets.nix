{
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.secrets = {
        getSecret = lib.mkOption {
          type = lib.types.raw;
          default = name: {
            _glueson = "execute";
            command = "${pkgs.sops}/bin/sops decrypt --extract '[\"${name}\"]' ${config.secrets.secretsFile}";
          };
        };
        secretsFile = lib.mkOption {
          type = lib.types.path;
        };
      };
    };
}
