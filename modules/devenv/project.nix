{ inputs ? {}, ... }:
let
  toolnixFlake = builtins.getFlake (toString ../..);
in {
  _module.args.inputs =
    inputs
    // {
      toolnix = toolnixFlake;
    }
    // toolnixFlake.devenvSources;

  imports = [ ./default.nix ];
}
