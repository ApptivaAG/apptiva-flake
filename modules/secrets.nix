{ apptiva-lib, ... }:
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
            command = "${pkgs.sops}/bin/sops decrypt --extract $name $secretsFile";
            params = {
              name = "[\"${name}\"]";
              secretsFile = config.secrets.secretsFile;
            };
            env = config.secrets.sopsEnv;
          };
        };
        secretsFile = lib.mkOption {
          type = lib.types.path;
        };
        sopsEnv = lib.mkOption {
          type = apptiva-lib.types.json;
          default = {
            GOOGLE_APPLICATION_CREDENTIALS = {
              _glueson = "evaluate";
              code = ''
                env.SECRET_DECRYPTION_SERVICE_ACCOUNT?{
                  _glueson: "temporary-file",
                  content: env.SECRET_DECRYPTION_SERVICE_ACCOUNT
                }:""
              '';
            };
          };
        };
      };
    };
}
