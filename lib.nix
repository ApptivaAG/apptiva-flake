{ flake-parts }:
{
  mkFlake =
    args: module:
    flake-parts.lib.mkFlake args {
      imports = [
        ./modules
        module
      ];
    };
}
