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
        description = "Reserved agent-browser opt-in; currently a no-op pending TLS remediation.";
      };
    };

    devenvOptionModule = { lib, ... }: {
      options.toolnix.agentBrowser.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Reserved agent-browser opt-in; currently a no-op pending TLS remediation.";
      };
    };
  };
}
