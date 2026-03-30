{ ... }: {
  flake = {
    lib.toolnix = {
      internal = {
        requiredBaselinePath = ../internal/shared/required-baseline.nix;
        requiredBaseline = import ../internal/shared/required-baseline.nix;
      };

      features.requiredBaseline = {
        data = import ../internal/shared/required-baseline.nix;

        homeManagerModule = { pkgs, ... }:
          let
            required = import ../internal/shared/required-baseline.nix { inherit pkgs; };
          in {
            home.packages = required.homePackages;
            home.sessionVariables = required.env;
          };
      };

      profiles = {
        homeManager.defaultModule = {
          imports = [
            ({ pkgs, ... }:
              let
                required = import ../internal/shared/required-baseline.nix { inherit pkgs; };
              in {
                home.packages = required.homePackages;
                home.sessionVariables = required.env;
              })
            ../internal/home-manager/toolnix-host-base.nix
          ];
        };

        devenv.defaultModule = import ../internal/devenv/default-base.nix;
      };
    };
  };
}
