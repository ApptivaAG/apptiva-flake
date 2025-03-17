{
  lib,
  appName,
  target,
  config,
  ...
}:
let
  json = import ../../../json.nix { inherit lib; };
in
{
  options = {
    enable = lib.mkEnableOption false;
    namespace = lib.mkOption {
      type = lib.types.str;
      default = "${appName}-${target.name}";
    };
    resources = lib.mkOption {
      type = json;
      default = { };
    };
    deployment = lib.mkOption {
      type = json;
      default = { };
    };
    replicas = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };
    strategy = lib.mkOption {
      type = json;
      default = { };
    };
    template = lib.mkOption {
      type = json;
      default = { };
    };
    pod = lib.mkOption {
      type = json;
      default = { };
    };
    container = lib.mkOption {
      type = json;
      default = { };
    };
    image = lib.mkOption {
      type = lib.types.str;
    };
    port = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = if config.hostname == null then null else 80;
    };
    cpu.request = lib.mkOption {
      type = lib.types.str;
    };
    cpu.limit = lib.mkOption {
      type = lib.types.str;
    };
    memory.request = lib.mkOption {
      type = lib.types.str;
    };
    memory.limit = lib.mkOption {
      type = lib.types.str;
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = target.hostname;
    };
    ingress = lib.mkOption {
      type = json;
      default = { };
    };
  };
  config = {
    resources =
      {
        deployment = config.deployment;
      }
      // (
        if (config.port != null) then
          {
            service = {
              apiVersion = "v1";
              kind = "Service";
              metadata.name = "service";
              spec = {
                selector.label = "pod";
                ports = [
                  {
                    protocol = "TCP";
                    port = config.port;
                    targetPort = config.port;
                  }
                ];
              };
            };

            ingress = config.ingress;

            "letsencrypt-issuer" = {
              apiVersion = "cert-manager.io/v1";
              kind = "Issuer";
              metadata.name = "letsencrypt";
              spec.acme = {
                email = "info@apptiva.ch";
                server = "https://acme-v02.api.letsencrypt.org/directory";
                privateKeySecretRef.name = "letsencrypt-secret";
                solvers = [
                  {
                    http01.ingress.class = "nginx";
                  }
                ];
              };
            };
          }
        else
          { }
      );
    deployment = {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata.name = "deployment";
      spec = {
        selector.matchLabels.label = "pod";
        inherit (config) replicas strategy template;
      };
    };
    strategy = {
      type = "RollingUpdate";
      rollingUpdate = {
        maxSurge = 1;
        maxUnavailable = 0;
      };
    };
    template = {
      metadata.labels.label = "pod";
      spec = config.pod;
    };
    pod = {
      containers = [
        config.container
      ];
    };
    container = {
      name = "container";
      image = config.image;
      imagePullPolicy = "Always";
      resources.limits = {
        cpu = config.cpu.limit;
        memory = config.memory.limit;
      };
      resources.requests = {
        cpu = config.cpu.request;
        memory = config.memory.request;
      };

      ports =
        if (config.port != null) then
          [
            {
              containerPort = config.port;
            }
          ]
        else
          [ ];

      env = lib.mapAttrsToList (name: value: {
        inherit name;
        value = "ref+envsubst://$" + name;
      }) target.runtimeEnvironment;
    };

    ingress = {
      kind = "Ingress";
      apiVersion = "networking.k8s.io/v1";
      metadata = {
        name = "ingress";
        annotations = {
          "cert-manager.io/issuer" = "letsencrypt";
          "kubernetes.io/ingress.class" = "nginx";
        };
      };
      spec = {
        rules = [
          {
            host = config.hostname;
            http.paths = [
              {
                path = "/";
                pathType = "Prefix";
                backend.service = {
                  name = "service";
                  port.number = config.port;
                };
              }
            ];
          }
        ];
        tls = [
          {
            hosts = [ config.hostname ];
            secretName = "certificate";
          }
        ];
      };
    };
  };
}
