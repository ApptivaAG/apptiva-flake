{ self, ... }:
{
  perSystem = {
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
          registryPasswordSecret = lib.mkOption {
            type = lib.types.str;
            default = "CONTAINER_REGISTRY_PASSWORD";
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
        config.buildEnvironment = {
          CONTAINER_REGISTRY_URL.value = config.container.registryUrl;
          CONTAINER_REGISTRY_USERNAME.value = config.container.registryUsername;
          CONTAINER_REGISTRY_PASSWORD.secret = config.container.registryPasswordSecret;
          CONTAINER_IMAGE_NAME.value = config.container.imageName;
          CONTAINER_IMAGE_TAG.value = config.container.imageTag;
        };
      };
  };
}
