{ config, ... }: {
  flake.lib.toolnix = {
    inherit (config.toolnix) internal features profiles;
  };
}
