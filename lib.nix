{ flake-parts, glueson }:
{
  mkFlake =
    args: module:
    flake-parts.lib.mkFlake
      (
        args
        // {
          inputs = {
            inherit glueson flake-parts;
          } // args.inputs;
        }
      )
      {
        imports = [
          ./modules
          module
        ];
      };
}
