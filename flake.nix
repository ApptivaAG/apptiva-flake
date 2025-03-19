{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    glueson.url = "github:VanCoding/glueson";
  };

  outputs = inputs: {
    lib = import ./lib.nix {
      flake-parts = inputs.flake-parts;
      glueson = inputs.glueson;
    };
    flakeModules.apptiva = import ./modules;
  };
}
