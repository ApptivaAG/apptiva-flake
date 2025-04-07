{ lib, apptiva-lib, ... }:
{
  _module.args.apptiva-lib.types = {
    json = import ../json.nix { inherit lib; };
  };
  perSystem = {
    _module.args.apptiva-lib = apptiva-lib;
  };
}
