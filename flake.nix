{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: {
    lib = import ./lib.nix { flake-parts = inputs.flake-parts; };
    flakeModules.apptiva = import ./modules;
  };
}
