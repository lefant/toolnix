{ inputs ? {}, ... }:
let
  toolnixFlake = builtins.getFlake (toString ../..);
  mergedInputs =
    inputs
    // {
      toolnix = toolnixFlake;
    }
    // toolnixFlake.devenvSources;
in {
  imports = [
    ({ ... }: {
      _module.args.inputs = mergedInputs;
    })
    ./default.nix
  ];
}
