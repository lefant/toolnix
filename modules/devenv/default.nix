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
  ]) ++ agent.packages;

  env = required.env // opinionated.env // agent.env // {
    EDITOR = "emacsclient -c -t";
    VISUAL = "emacsclient -c -t";
  };

  enterShell = ''
    export TOOLNIX_SOURCE_DIR="${toolnixRoot}"
    export SKILLS_SOURCE_DIR="${resolvedInputs.agent-skills}"
    export PLUGINS_SOURCE_DIR="${resolvedInputs.claude-code-plugins}"
    export TZ="${opinionated.env.TZ}"
${agent.enterShell}

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
}
