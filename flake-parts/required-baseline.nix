{ ... }: {
  flake.lib.toolnix.internal = {
    requiredBaselinePath = ../internal/shared/required-baseline.nix;
    requiredBaseline = import ../internal/shared/required-baseline.nix;
  };
}
