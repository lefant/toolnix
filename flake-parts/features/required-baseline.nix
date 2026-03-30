{ ... }:
let
  requiredBaselinePath = ../../internal/shared/required-baseline.nix;
  requiredBaselineData = import requiredBaselinePath;
in {
  config.toolnix.internal = {
    requiredBaselinePath = requiredBaselinePath;
    requiredBaseline = requiredBaselineData;
  };

  config.toolnix.features.requiredBaseline = {
    data = requiredBaselineData;

    homeManagerModule = { pkgs, ... }:
      let
        required = requiredBaselineData { inherit pkgs; };
      in {
        home.packages = required.homePackages;
        home.sessionVariables = required.env;
      };

    devenvModule = { pkgs, ... }:
      let
        required = requiredBaselineData { inherit pkgs; };
      in {
        packages = required.packages;
        env = required.env;
      };
  };
}
