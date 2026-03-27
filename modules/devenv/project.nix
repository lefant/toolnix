args@{ inputs ? {}, ... }:
let
  toolnixFlake = builtins.getFlake (toString ../..);
in
import ./default.nix (args // {
  inputs =
    inputs
    // {
      toolnix = toolnixFlake;
    }
    // toolnixFlake.devenvSources;
})
