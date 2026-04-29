{ ... }:
let
  compoundEngineeringData = import ../../modules/shared/compound-engineering.nix;
in {
  config.toolnix.features.compoundEngineering = {
    data = compoundEngineeringData;

    homeManagerOptionModule = { lib, ... }: {
      options.toolnix.compoundEngineering = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable the EveryInc Compound Engineering integration by default for Home Manager hosts.";
        };

        skills.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Compound Engineering skills into the managed agent skill tree when Compound Engineering is enabled.";
        };

        pi.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Pi-specific Compound Engineering agent assets when Compound Engineering is enabled.";
        };

        pi.subagentExtension.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install the Pi subagent extension used by Compound Engineering agents.";
        };
      };
    };
  };
}
