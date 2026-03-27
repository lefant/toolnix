{ pkgs }:
let
  sharedPackages = with pkgs; [
    mg
    bat
    tmux
    just
    gh
    git
  ];
in {
  packages = sharedPackages;

  # Keep Home Manager on the proven narrow set for now to avoid collisions
  # with preexisting nix-profile ownership on deployed hosts.
  homePackages = with pkgs; [
    mg
    bat
    tmux
    just
  ];

  env = {
    LANG = "C.UTF-8";
    LC_ALL = "C.UTF-8";
  };
}
