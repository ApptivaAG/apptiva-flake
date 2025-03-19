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
    in
    {
      config = {
        allTargets =
          { config, ... }:
          let
            resources = lib.mapAttrsToList (name: value: value) config.kubernetes.resources;
          in
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
              default = { };
            };
            config = lib.mkIf config.kubernetes.enable {
              packages.print-kubernetes-resources = pkgs.writeGluesonApplication {
                name = "print-kubernetes-resources";
                value = resources;
              };
              packages.deploy = pkgs.writeGluesonApplication {
                name = "deploy";
                value = {
                  _glueson = "execute";
                  command = "helm upgrade --install -f - --namespace \${namespace} --create-namespace app ${./helm}";
                  params = {
                    namespace = config.kubernetes.namespace;
                  };
                  stdin = {
                    inherit resources;
                  };
                  output = "log";
                };
              };
              packages.undeploy = pkgs.writeGluesonApplication {
                name = "deploy";
                value = {
                  _glueson = "execute";
                  command = "helm uninstall --namespace \${namespace} app";
                  params = {
                    namespace = config.kubernetes.namespace;
                  };
                  stdin = {
                    inherit resources;
                  };
                  output = "log";
                };
              };
            };
          };
      };
    };
}
