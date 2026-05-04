{ pkgs, lib, config, inputs, toolnixFeatures, ... }:
let
  toolnixRoot = ../../..;
  features = toolnixFeatures;
  toolnixFlake = inputs.toolnix or (builtins.getFlake (toString toolnixRoot));
  resolvedInputs =
    if inputs ? "agent-skills" && inputs ? "claude-code-plugins" && inputs ? "llm-agents"
    then inputs
    else toolnixFlake.devenvSources // { toolnix = toolnixFlake; };
  opinionated = features.opinionatedShell.data { inherit pkgs; };
  agent = features.agentBaseline.data { inherit pkgs lib; inputs = resolvedInputs; };
  compound = features.compoundEngineering.data { inherit pkgs lib; inputs = resolvedInputs; };
  agentBrowser = features.agentBrowser.data { inherit pkgs; };
in {
  config =
    let
      opinionatedCfg = config.toolnix.opinionated;
      useTimezone = opinionatedCfg.enable && opinionatedCfg.timezone.enable;
      useAliases = opinionatedCfg.enable && opinionatedCfg.aliases.enable;
      useTmuxHelpers = opinionatedCfg.enable && opinionatedCfg.tmuxHelpers.enable;
      useAgentWrappers = opinionatedCfg.enable && opinionatedCfg.agentWrappers.enable;
      useAgentBrowser = config.toolnix.agentBrowser.enable;
      useCompoundTools = config.toolnix.compoundEngineering.enable && config.toolnix.compoundEngineering.tools.enable;
      projectOpinionatedShell = opinionated.renderProjectShell {
        includeAliases = useAliases;
        includeTmuxHelpers = useTmuxHelpers;
        includeAgentWrappers = useAgentWrappers;
      };
    in {
      packages = with pkgs; [
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
      ] ++ agent.packages ++ lib.optionals useCompoundTools compound.toolPackages ++ lib.optionals useAgentBrowser agentBrowser.packages;

      env =
        lib.optionalAttrs useTimezone opinionated.env
        // agent.env
        // lib.optionalAttrs useAgentBrowser agentBrowser.env
        // {
          EDITOR = "emacsclient -c -t";
          VISUAL = "emacsclient -c -t";
        };

      enterShell = ''
        export TOOLNIX_SOURCE_DIR="${toolnixRoot}"
${lib.optionalString useTimezone ''        export TZ="${opinionated.env.TZ}"''}

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
      '';
    };
}
