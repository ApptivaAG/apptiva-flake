{ self, ... }:
{
  perSystem =
    { config, ... }:
    let
      systemConfig = config;
    in
    {
      allTargets =
        {
          rootConfig,
          config,
          lib,
          ...
        }:
        {
          options.container = {
            registryUrl = lib.mkOption {
              type = lib.types.str;
              default = "europe-west6-docker.pkg.dev/kubernetes-283408/docker/";
            };
            registryUsername = lib.mkOption {
              type = lib.types.str;
              default = "_json_key";
            };
            registryPassword = lib.mkOption {
              type = lib.types.str;
              default = systemConfig.secrets.getSecret "CONTAINER_REGISTRY_PASSWORD";
            };
            imageName = lib.mkOption {
              type = lib.types.str;
              default = rootConfig.appName;
            };
            imageTag = lib.mkOption {
              type = lib.types.str;
              default = self.rev or "dirty";
            };
          };
        };
    };
}
