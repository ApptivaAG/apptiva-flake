{
  imports = [
    ./app-name.nix
    ./dependencies.nix
    ./default-dependencies.nix
    ./targets
    ./nixpkgs.nix
    ./secrets.nix
    ./apptiva-lib.nix
  ];
  systems = [
    "x86_64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}
