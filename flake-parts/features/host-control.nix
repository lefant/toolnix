{ ... }:
let
  hostControlData = import ../../modules/shared/host-control.nix;
in {
  config.toolnix.features.hostControl = {
    data = hostControlData;

    homeManagerOptionModule = { lib, ... }: {
      options.toolnix.enableHostControl = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable host/control-only shell helpers such as tmux-meta.";
      };
    };
  };
}
