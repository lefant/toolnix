{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      opinionated = import ../modules/shared/opinionated-shell.nix { inherit pkgs; };
      agent = import ../modules/shared/agent-baseline.nix {
        inherit pkgs;
        lib = pkgs.lib;
        inputs = inputs // { toolnix = inputs.self or null; };
      };
      llmAgentsPkgs = inputs.llm-agents.packages.${system};
      tmuxConf = pkgs.writeText "toolnix-wrapped-tmux.conf" (opinionated.renderTmuxConf { });
      piSettings = ../agents/pi-coding-agent/templates/settings.json;
      piKeybindings = ../agents/pi-coding-agent/templates/keybindings.json;
      piQnaExtension = ../agents/pi-coding-agent/extensions/qna.ts;
      piAskUserExtension = ../agents/pi-coding-agent/extensions/ask-user.ts;
      piLoopExtension = ../agents/pi-coding-agent/extensions/loop.ts;
      piAgents = ../agents/shared/templates/caveman-lite-context.md;
      toolnixTmux = pkgs.writeShellApplication {
        name = "toolnix-tmux";
        runtimeInputs = [ pkgs.tmux pkgs.coreutils pkgs.zsh ];
        text = ''
          set -euo pipefail

          socket="''${TOOLNIX_TMUX_SOCKET:-toolnix}"
          session="''${TOOLNIX_TMUX_SESSION:-toolnix}"
          conf="${tmuxConf}"

          if [ "$#" -eq 0 ]; then
            exec ${pkgs.tmux}/bin/tmux -L "$socket" -f "$conf" new-session -A -s "$session"
          else
            exec ${pkgs.tmux}/bin/tmux -L "$socket" -f "$conf" "$@"
          fi
        '';
      };
      toolnixPi = pkgs.writeShellApplication {
        name = "toolnix-pi";
        runtimeInputs = [ llmAgentsPkgs.pi pkgs.coreutils pkgs.findutils ];
        text = ''
          set -euo pipefail

          state_root="''${TOOLNIX_WRAPPED_STATE_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/toolnix}"
          agent_dir="''${PI_CODING_AGENT_DIR:-$state_root/pi/agent}"

          mkdir -p "$agent_dir" "$agent_dir/extensions"

          link_managed_file() {
            local source="$1"
            local target="$2"

            if [ ! -e "$target" ] && [ ! -L "$target" ]; then
              ln -s "$source" "$target"
            elif [ -L "$target" ] && [ ! -e "$target" ]; then
              ln -sfn "$source" "$target"
            fi
          }

          link_managed_file "${piSettings}" "$agent_dir/settings.json"
          link_managed_file "${piKeybindings}" "$agent_dir/keybindings.json"
          link_managed_file "${piAgents}" "$agent_dir/AGENTS.md"
          link_managed_file "${piQnaExtension}" "$agent_dir/extensions/qna.ts"
          link_managed_file "${piAskUserExtension}" "$agent_dir/extensions/ask-user.ts"
          link_managed_file "${piLoopExtension}" "$agent_dir/extensions/loop.ts"

          link_managed_file "${agent.managedSkillTree}" "$agent_dir/skills"

          if [ -f "$HOME/.pi/agent/auth.json" ]; then
            link_managed_file "$HOME/.pi/agent/auth.json" "$agent_dir/auth.json"
          fi

          export PI_CODING_AGENT_DIR="$agent_dir"
          export PI_SKIP_VERSION_CHECK=1
          export TOOLNIX_SOURCE_DIR="${../.}"
          export BEADS_NO_DAEMON=1
          export CODEX_CHECK_FOR_UPDATE_ON_STARTUP=false
          export DISABLE_AUTOUPDATER=1
          export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
          export AMP_SKIP_UPDATE_CHECK=1

          exec ${llmAgentsPkgs.pi}/bin/pi "$@"
        '';
      };
    in {
      packages = {
        toolnix-tmux = toolnixTmux;
        toolnix-pi = toolnixPi;
      };

      apps = {
        toolnix-tmux = {
          type = "app";
          program = "${toolnixTmux}/bin/toolnix-tmux";
        };
        toolnix-pi = {
          type = "app";
          program = "${toolnixPi}/bin/toolnix-pi";
        };
      };
    };
}
