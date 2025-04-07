{
  lib,
  apptiva-lib,
  appName,
  target,
  config,
  systemConfig,
  pkgs,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption false;
    namespace = lib.mkOption {
      type = lib.types.str;
      default = "${appName}-${target.name}";
    };
    resources = lib.mkOption {
      type = apptiva-lib.types.json;
      default = { };
    };
    deployment = lib.mkOption {
      type = apptiva-lib.types.json;
      default = { };
    };
    replicas = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };
    strategy = lib.mkOption {
      type = apptiva-lib.types.json;
      default = { };
    };
    template = lib.mkOption {
      type = apptiva-lib.types.json;
      default = { };
    };
    pod = lib.mkOption {
      type = apptiva-lib.types.json;
      default = { };
    };
    container = lib.mkOption {
      type = apptiva-lib.types.json;
      default = { };
    };
    image = lib.mkOption {
      type = apptiva-lib.types.json;
      default = target.container.imagePath;
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
      type = apptiva-lib.types.json;
      default = { };
    };
    kubeconfigContent = lib.mkOption {
      type = apptiva-lib.types.json;
      default = systemConfig.secrets.getSecret "KUBECONFIG_CONTENT";
    };
    kubeconfigFile = lib.mkOption {
      type = apptiva-lib.types.json;
      default = {
        _glueson = "temporary-file";
        content = config.kubeconfigContent;
      };
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
        inherit name value;
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
