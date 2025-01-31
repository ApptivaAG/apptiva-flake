{
  perSystem =
    { pkgs, ... }:
    {
      devDependencies = [
        pkgs.nixfmt-rfc-style
      ];
    };
}
