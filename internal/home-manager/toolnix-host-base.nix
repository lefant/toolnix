{ config, lib, pkgs, inputs, ... }:
let
  toolnixRoot = ../..;
  cfg = config.toolnix;
  agent = import ../../modules/shared/agent-baseline.nix { inherit pkgs lib inputs; };
  agentBrowser = import ../../modules/shared/agent-browser.nix { inherit pkgs; };
  opinionated = import ../../modules/shared/opinionated-shell.nix { inherit pkgs; };
  hostControl = import ../../modules/shared/host-control.nix { inherit pkgs; };
in {
  options.toolnix.hostName = lib.mkOption {
    type = lib.types.str;
    default = "toolnix";
    description = "Short host label used in the tmux status line.";
  };

  options.toolnix.enableHostControl = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable host/control-only shell helpers such as tmux-meta.";
  };

  options.toolnix.enableAgentBaseline = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable the shared agent baseline on Home Manager hosts.";
  };

  options.toolnix.agentBrowser.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable opt-in host-native agent-browser support on the host.";
  };

  config = {
    programs.home-manager.enable = true;

    home.packages =
      lib.optionals cfg.enableAgentBaseline agent.packages
      ++ lib.optionals cfg.agentBrowser.enable agentBrowser.packages;
    home.sessionVariables =
      opinionated.env
      // lib.optionalAttrs cfg.enableAgentBaseline agent.env
      // lib.optionalAttrs cfg.agentBrowser.enable agentBrowser.env;

    home.file.".zshrc".text = ''
      source ~/.zsh/zshrc.sh
    '';
    home.file.".zsh/zshrc.sh".text = opinionated.renderZshRc {
      extraBody = lib.optionalString cfg.enableHostControl hostControl.zshBody;
    };
    home.file.".zsh/zshlocal.sh".text = ''
      # Keep this minimal by default. Source runtime credentials until they
      # move to a better injection path.
      if [ -f "$HOME/.env.toolnix" ]; then
        set -a
        . "$HOME/.env.toolnix"
        set +a
      elif [ -f "$HOME/.env.toolbox" ]; then
        set -a
        . "$HOME/.env.toolbox"
        set +a
      fi
    '';
    home.file.".zshenv".text = ''
      if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi
    '';
    home.file.".gitconfig".source = ../../home-manager/files/gitconfig;
    home.file.".gitconfig.altego".source = ../../home-manager/files/gitconfig.altego;
    home.file.".gitconfig.gh-auth".source = ../../home-manager/files/gitconfig.gh-auth;
    home.file.".ssh/config".source = ../../home-manager/files/ssh-config;
    home.file.".claude/settings.json" = {
      source = ../../agents/claude/templates/settings.json;
      force = true;
    };
    home.file.".codex/config.toml" = {
      source = ../../agents/codex/templates/config.toml;
      force = true;
    };
    home.file.".config/opencode/opencode.json" = {
      source = ../../agents/opencode/templates/opencode.json;
      force = true;
    };
    home.file.".config/amp/settings.json" = {
      source = ../../agents/amp/templates/settings.json;
      force = true;
    };
    home.file.".openclaw/openclaw.json" = {
      source = ../../agents/openclaw/templates/openclaw.json;
      force = true;
    };
    home.file.".pi/agent/settings.json" = {
      source = ../../agents/pi-coding-agent/templates/settings.json;
      force = true;
    };
    home.file.".pi/agent/keybindings.json" = {
      source = ../../agents/pi-coding-agent/templates/keybindings.json;
      force = true;
    };
    home.file.".agents/skills" = {
      source = agent.managedSkillTree;
      force = true;
    };
    home.file.".claude/skills" = {
      source = agent.managedSkillTree;
      force = true;
    };
    home.file.".config/opencode/skills" = {
      source = agent.managedSkillTree;
      force = true;
    };
    home.file.".config/amp/skills" = {
      source = agent.managedSkillTree;
      force = true;
    };
    home.file.".openclaw/skills" = {
      source = agent.managedSkillTree;
      force = true;
    };
    home.file.".pi/agent/skills" = {
      source = agent.managedSkillTree;
      force = true;
    };
    home.file.".tmux.conf".text = opinionated.renderTmuxConf { };
    home.file.".tmux.conf.meta" = lib.mkIf cfg.enableHostControl {
      text = hostControl.tmuxConf;
    };

    home.activation.seedClaudeRuntimeState =
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        claude_template="${toolnixRoot}/agents/claude/templates/dot-claude.json"
        claude_json="${config.home.homeDirectory}/.claude.json"
        tmp_json="$(mktemp)"

        if [ -f "$claude_template" ]; then
          if [ -f "$claude_json" ]; then
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$claude_template" "$claude_json" > "$tmp_json"
          else
            cp "$claude_template" "$tmp_json"
          fi

          ${pkgs.coreutils}/bin/install -m 600 "$tmp_json" "$claude_json"
          rm -f "$tmp_json"
        fi
      '';
  };
}
