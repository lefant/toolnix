args:
let
  toolnixFlake = builtins.getFlake (toString ../..);
in
toolnixFlake.homeManagerModules.default args
