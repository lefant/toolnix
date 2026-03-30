args:
let
  toolnixFlake = builtins.getFlake (toString ../..);
in
toolnixFlake.devenvModules.default args
