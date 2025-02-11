{
  imports = [
    ./app-name.nix
    ./dependencies.nix
    ./default-dependencies.nix
    ./dev-shell.nix
    ./targets
    ./kubernetes.nix
  ];
  systems = [
    "x86_64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}
