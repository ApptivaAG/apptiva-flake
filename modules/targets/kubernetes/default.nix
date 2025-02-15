{
  lib,
  config,
  ...
}:
let
  rootConfig = config;
in
{
  perSystem =
    { config, pkgs, ... }:
    let
      systemConfig = config;
      targetKubernetesSettings = pkgs.writeText "target-kubernetes-settings.json" (
        builtins.toJSON (
          lib.mapAttrs (name: value: ({
            namespace = value.kubernetes.namespace;
            resources = lib.mapAttrsToList (name: value: value) value.kubernetes.resources;
          })) config.targets
        )
      );
    in
    {
      config = {
        allTargets =
          { config, ... }:
          {
            options.kubernetes = lib.mkOption {
              type = lib.types.submoduleWith {
                modules = [
                  ./options.nix
                ];
                specialArgs = {
                  inherit (rootConfig) appName;
                  target = config;
                };
              };
            };
            config = {
              deployCommand = "${systemConfig.packages.deploy-to-kubernetes}/bin/deploy-to-kubernetes";
            };
          };
        packages.deploy-to-kubernetes = pkgs.writeShellApplication {
          name = "deploy-to-kubernetes";
          runtimeInputs = [
            pkgs.kubernetes-helm
            systemConfig.packages.get-target-from-file
            systemConfig.substitute-secrets
          ];
          text = ''
            NAMESPACE=$(get-target-from-file ${targetKubernetesSettings} "$1.namespace")
            get-target-from-file ${targetKubernetesSettings} "$1" | substitute-secrets | helm upgrade --install -f - --namespace "$NAMESPACE" --create-namespace app ${./helm}
          '';
        };
      };
    };
}
