{ ... }:
let
  agentBaselineData = import ../../modules/shared/agent-baseline.nix;
in {
  config.toolnix.features.agentBaseline = {
    data = agentBaselineData;

    homeManagerOptionModule = { lib, ... }: {
      options.toolnix.enableAgentBaseline = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the shared agent baseline on Home Manager hosts.";
      };
    };
  };
}
