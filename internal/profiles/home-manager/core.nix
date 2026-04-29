{ config, lib, pkgs, inputs, toolnixFeatures, ... }:
let
  toolnixRoot = ../../..;
  features = toolnixFeatures;
  cfg = config.toolnix;
  agent = features.agentBaseline.data { inherit pkgs lib inputs; };
  compound = features.compoundEngineering.data { inherit pkgs lib inputs; };
  agentBrowser = features.agentBrowser.data { inherit pkgs; };
  opinionated = features.opinionatedShell.data { inherit pkgs; };
  compoundSkillsEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.skills.enable;
  compoundOpenCodeEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.opencode.enable;
  compoundPiEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.pi.enable;
  managedSkillTree =
    if compoundSkillsEnabled then
      agent.mkManagedSkillTree "toolnix-managed-skills-with-compound-engineering" (agent.skillLinks ++ compound.skillLinks)
    else
      agent.managedSkillTree;
  opencodeManagedSkillTree =
    if compoundOpenCodeEnabled then
      agent.mkManagedSkillTree "toolnix-managed-opencode-skills-with-compound-engineering" (agent.skillLinks ++ compound.opencodeSkillLinks)
    else
      managedSkillTree;
  hostControl = features.hostControl.data { inherit pkgs; };
in {
  options.toolnix.hostName = lib.mkOption {
    type = lib.types.str;
    default = "toolnix";
    description = "Short host label used in the tmux status line.";
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
      extraBody = lib.concatStringsSep "\n" (
        [ hostControl.tmuxMetaBody ]
        ++ lib.optionals cfg.enableHostControl [ hostControl.controlHostBody ]
      );
    };
    home.file.".zsh/completion".source = ../../../home-manager/files/zsh-completion;
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
    home.file.".gitconfig".source = ../../../home-manager/files/gitconfig;
    home.file.".gitconfig.altego".source = ../../../home-manager/files/gitconfig.altego;
    home.file.".gitconfig.gh-auth".source = ../../../home-manager/files/gitconfig.gh-auth;
    home.file.".ssh/config".source = ../../../home-manager/files/ssh-config;
    home.file.".claude/settings.json" = {
      source = ../../../agents/claude/templates/settings.json;
      force = true;
    };
    home.file.".claude/CLAUDE.md" = {
      source = ../../../agents/shared/templates/caveman-lite-context.md;
      force = true;
    };
    home.file.".codex/config.toml" = {
      source = ../../../agents/codex/templates/config.toml;
      force = true;
    };
    home.file.".codex/AGENTS.md" = {
      source = ../../../agents/shared/templates/caveman-lite-context.md;
      force = true;
    };
    home.file.".config/opencode/opencode.json" = {
      source = ../../../agents/opencode/templates/opencode.json;
      force = true;
    };
    home.file.".config/amp/settings.json" = {
      source = ../../../agents/amp/templates/settings.json;
      force = true;
    };
    home.file.".pi/agent/settings.json" = {
      source = ../../../agents/pi-coding-agent/templates/settings.json;
      force = true;
    };
    home.file.".pi/agent/keybindings.json" = {
      source = ../../../agents/pi-coding-agent/templates/keybindings.json;
      force = true;
    };
    home.file.".pi/agent/AGENTS.md" = {
      source = ../../../agents/shared/templates/caveman-lite-context.md;
      force = true;
    };
    home.file.".pi/agent/extensions/qna.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/qna.ts;
      force = true;
    };
    home.file.".pi/agent/extensions/loop.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/loop.ts;
      force = true;
    };
    home.file.".agents/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = managedSkillTree;
      force = true;
    };
    home.file.".claude/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = managedSkillTree;
      force = true;
    };
    home.file.".config/opencode/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = opencodeManagedSkillTree;
      force = true;
    };
    home.file.".config/opencode/agents" = lib.mkIf compoundOpenCodeEnabled {
      source = compound.managedOpenCodeAgentTree;
      force = true;
    };
    home.file.".config/amp/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = managedSkillTree;
      force = true;
    };
    home.file.".openclaw/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = managedSkillTree;
      force = true;
    };
    home.file.".pi/agent/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = managedSkillTree;
      force = true;
    };
    home.file.".pi/agent/agents" = lib.mkIf compoundPiEnabled {
      source = compound.managedAgentTree;
      force = true;
    };
    home.file.".pi/agent/extensions/subagent" = lib.mkIf (compoundPiEnabled && cfg.compoundEngineering.pi.subagentExtension.enable) {
      source = compound.piSubagentExtension;
      force = true;
    };
    home.file.".tmux.conf".text = opinionated.renderTmuxConf { };
    home.file.".tmux.conf.meta".text = hostControl.tmuxConf;

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
