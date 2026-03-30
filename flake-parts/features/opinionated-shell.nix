{ ... }:
let
  opinionatedShellData = import ../../modules/shared/opinionated-shell.nix;
in {
  config.toolnix.features.opinionatedShell = {
    data = opinionatedShellData;

    devenvOptionModule = { lib, ... }: {
      options.toolnix.opinionated.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the shared opinionated shell layer in project devenv shells.";
      };

      options.toolnix.opinionated.timezone.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Stockholm timezone defaults in the project shell.";
      };

      options.toolnix.opinionated.aliases.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable opinionated shell aliases such as e in the project shell.";
      };

      options.toolnix.opinionated.tmuxHelpers.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux helper functions such as tmux-here in the project shell.";
      };

      options.toolnix.opinionated.agentWrappers.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable opinionated claude/codex wrapper aliases in the project shell.";
      };
    };
  };
}
