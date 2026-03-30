{ ... }:
let
  agentBrowserData = import ../../modules/shared/agent-browser.nix;
in {
  config.toolnix.features.agentBrowser = {
    data = agentBrowserData;

    homeManagerOptionModule = { lib, ... }: {
      options.toolnix.agentBrowser.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable opt-in host-native agent-browser support on the host.";
      };
    };

    devenvOptionModule = { lib, ... }: {
      options.toolnix.agentBrowser.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable opt-in host-native agent-browser support in the project shell.";
      };
    };
  };
}
