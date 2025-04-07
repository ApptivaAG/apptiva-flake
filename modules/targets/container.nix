{
  self,
  lib,
  apptiva-lib,
  ...
}:
{
  perSystem =
    { config, pkgs, ... }:
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
              type = apptiva-lib.types.json;
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
            imagePath = lib.mkOption {
              type = apptiva-lib.types.json;
              default = {
                _glueson = "evaluate";
                code = "`\${registryUrl}\${imageName}:\${imageTag}`";
                params = {
                  registryUrl = config.container.registryUrl;
                  imageName = config.container.imageName;
                  imageTag = config.container.imageTag;
                };
              };
            };
            streamLayeredImage = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
            };
            push-image = lib.mkOption {
              type = apptiva-lib.types.json;
              default =
                let
                  push-layered-image-stream = pkgs.writeShellApplication {
                    name = "push-layered-image-stream";
                    runtimeInputs = [
                      pkgs.skopeo
                      pkgs.gzip
                    ];
                    text = ''"$STREAM_LAYERED_IMAGE" | gzip --fast | skopeo copy docker-archive:/dev/stdin "docker://$IMAGE_PATH" --dest-creds "$USERNAME:$PASSWORD" --insecure-policy'';
                  };
                in
                {
                  _glueson = "execute";
                  command = "${push-layered-image-stream}/bin/push-layered-image-stream";
                  env = {
                    STREAM_LAYERED_IMAGE = "${config.container.streamLayeredImage}";
                    IMAGE_PATH = config.container.imagePath;
                    USERNAME = config.container.registryUsername;
                    PASSWORD = config.container.registryPassword;
                  };
                  log = true;
                };
            };
          };
          config = {
            packages.push-container-image = pkgs.writeGluesonApplication {
              name = "push-container-image";
              value = config.container.push-image;
            };
          };
        };
    };
}
