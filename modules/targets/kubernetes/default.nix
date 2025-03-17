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
            resources = {
              resources = lib.mapAttrsToList (name: value: value) value.kubernetes.resources;
            };
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
              buildEnvironment = {
                KUBERNETES_RESOURCES.value = "${targetKubernetesSettings}";
                KUBERNETES_NAMESPACE.value = config.kubernetes.namespace;
              };
            };
          };
        packages.print-kubernetes-resources = pkgs.writeShellApplication {
          name = "print-kubernetes-resources";
          runtimeInputs = [
            systemConfig.packages.get-target-value
            systemConfig.substitute-secrets
          ];
          text = ''
            TARGET_CONFIGURATIONS=$KUBERNETES_RESOURCES get-target-value resources | substitute-secrets
          '';
        };
        packages.deploy-to-kubernetes = pkgs.writeShellApplication {
          name = "deploy-to-kubernetes";
          runtimeInputs = [
            pkgs.kubernetes-helm
            systemConfig.packages.print-kubernetes-resources
          ];
          text = ''
            print-kubernetes-resources | helm upgrade --install -f - --namespace "$KUBERNETES_NAMESPACE" --create-namespace app ${./helm}
          '';
        };
      };
    };
}
