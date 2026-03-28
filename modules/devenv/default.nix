{ pkgs, lib, config, inputs, ... }:
let
  toolnixRoot = ../..;
  toolnixFlake = builtins.getFlake (toString toolnixRoot);
  resolvedInputs =
    if inputs ? "agent-skills" && inputs ? "claude-code-plugins" && inputs ? "llm-agents"
    then inputs
    else toolnixFlake.devenvSources // { toolnix = toolnixFlake; };
  required = import ../shared/required-baseline.nix { inherit pkgs; };
  opinionated = import ../shared/opinionated-shell.nix { inherit pkgs; };
  agent = import ../shared/agent-baseline.nix { inherit pkgs lib; inputs = resolvedInputs; };
  agentBrowser = import ../shared/agent-browser.nix { inherit pkgs; };
in {
  options.toolnix.agentBrowser.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable opt-in host-native agent-browser support in the project shell.";
  };

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

  config =
    let
      opinionatedCfg = config.toolnix.opinionated;
      useTimezone = opinionatedCfg.enable && opinionatedCfg.timezone.enable;
      useAliases = opinionatedCfg.enable && opinionatedCfg.aliases.enable;
      useTmuxHelpers = opinionatedCfg.enable && opinionatedCfg.tmuxHelpers.enable;
      useAgentWrappers = opinionatedCfg.enable && opinionatedCfg.agentWrappers.enable;
      useAgentBrowser = config.toolnix.agentBrowser.enable;
      projectOpinionatedShell = opinionated.renderProjectShell {
        includeAliases = useAliases;
        includeTmuxHelpers = useTmuxHelpers;
        includeAgentWrappers = useAgentWrappers;
      };
    in {
  packages = required.packages ++ (with pkgs; [
    zsh
    emacs-nox
    vim
    fzf
    tree
    htop
    ncdu
    ripgrep
    jq
    curl
    wget
    socat
    openssh
    rsync
    unzip
    shellcheck
    procps
    less
  ]) ++ agent.packages ++ lib.optionals useAgentBrowser agentBrowser.packages;

  env = required.env
    // lib.optionalAttrs useTimezone opinionated.env
    // agent.env
    // lib.optionalAttrs useAgentBrowser agentBrowser.env
    // {
    EDITOR = "emacsclient -c -t";
    VISUAL = "emacsclient -c -t";
  };

  enterShell = ''
    export TOOLNIX_SOURCE_DIR="${toolnixRoot}"
    export SKILLS_SOURCE_DIR="${resolvedInputs.agent-skills}"
    export PLUGINS_SOURCE_DIR="${resolvedInputs.claude-code-plugins}"
${lib.optionalString useTimezone ''    export TZ="${opinionated.env.TZ}"''}
${agent.enterShell}

${projectOpinionatedShell}

    if [ -f "$HOME/.env.toolnix" ]; then
      set -a
      source "$HOME/.env.toolnix"
      set +a
    elif [ -f "$HOME/.env.toolbox" ]; then
      set -a
      source "$HOME/.env.toolbox"
      set +a
    fi

    TOOLNIX_SEED_ONLY=1 "${toolnixRoot}/scripts/toolnix-setup-hook.sh" true
  '';
};
}
