{ config, lib, pkgs, inputs, toolnixFeatures, ... }:
let
  features = toolnixFeatures;
  cfg = config.toolnix;
  agent = features.agentBaseline.data { inherit pkgs lib inputs; };
  agentBrowser = features.agentBrowser.data { inherit pkgs lib inputs; };
  compound = features.compoundEngineering.data { inherit pkgs lib inputs; };
  compoundSkillsEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.skills.enable;
  compoundOpenCodeEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.opencode.enable;
  compoundOpenCodeSkillsEnabled = compoundSkillsEnabled && cfg.compoundEngineering.opencode.enable;
  compoundClaudeEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.claude.enable;
  compoundClaudeSkillsEnabled = compoundSkillsEnabled && cfg.compoundEngineering.claude.enable;
  compoundCodexEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.codex.enable;
  compoundCodexSkillsEnabled = compoundSkillsEnabled && cfg.compoundEngineering.codex.enable;
  compoundPiEnabled = cfg.enableAgentBaseline && cfg.compoundEngineering.enable && cfg.compoundEngineering.pi.enable;
  compoundToolsEnabled = cfg.compoundEngineering.enable && cfg.compoundEngineering.tools.enable;
  compatibility = config.toolnix.agentLinuxForceCompatibility;
  agentTargets = [
    ".claude/settings.json" ".claude/CLAUDE.md" ".codex/config.toml" ".codex/AGENTS.md"
    ".config/opencode/opencode.json" ".config/amp/settings.json"
    ".pi/agent/settings.json" ".pi/agent/keybindings.json" ".pi/agent/AGENTS.md"
    ".pi/agent/extensions/qna.ts" ".pi/agent/extensions/ask-user.ts"
    ".pi/agent/extensions/loop.ts" ".pi/agent/extensions/login-url-padding.ts"
    ".agents/skills" ".claude/skills" ".claude/agents"
    ".config/opencode/skills" ".config/opencode/agents"
    ".codex/skills/compound-engineering" ".codex/skills/matt-pocock"
    ".codex/skills/antithesis" ".codex/agents/compound-engineering"
    ".config/amp/skills" ".pi/agent/skills" ".pi/agent/agents"
    ".pi/agent/extensions/subagent"
  ];
  managedTargets = map (name: config.home.file.${name}.target) (
    builtins.filter (name: builtins.hasAttr name config.home.file && config.home.file.${name}.enable) agentTargets
  );
  managedSkillTree =
    if compoundSkillsEnabled then
      agent.mkManagedSkillTree "toolnix-managed-skills-with-compound-engineering" (agent.skillLinks ++ compound.skillLinks)
    else
      agent.managedSkillTree;
  ampManagedSkillTree =
    if compoundSkillsEnabled then
      agent.mkManagedSkillTree "toolnix-managed-amp-skills-with-compound-engineering" (agent.ampSkillLinks ++ compound.skillLinks)
    else
      agent.managedAmpSkillTree;
  opencodeManagedSkillTree =
    if compoundOpenCodeSkillsEnabled then
      agent.mkManagedSkillTree "toolnix-managed-opencode-skills-with-compound-engineering" (agent.skillLinks ++ compound.opencodeSkillLinks)
    else
      agent.managedSkillTree;
  claudeManagedSkillTree =
    if compoundClaudeSkillsEnabled then
      agent.mkManagedSkillTree "toolnix-managed-claude-skills-with-compound-engineering" (agent.skillLinks ++ compound.rawSkillLinks)
    else
      agent.managedSkillTree;
in {
  options.toolnix.agentLinuxForceCompatibility = lib.mkOption {
    type = lib.types.bool;
    default = false;
    internal = true;
    description = "Retain legacy forced agent links in the full Linux host profile.";
  };
  config = {
    home.activation.toolnixAdoptAgents = lib.mkIf (!compatibility) (
      lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        ${pkgs.bash}/bin/bash ${../../../scripts/agent-adoption.sh} ${lib.concatMapStringsSep " " lib.escapeShellArg managedTargets}
      ''
    );
    home.packages =
      lib.optionals cfg.enableAgentBaseline agent.packages
      ++ lib.optionals compoundToolsEnabled compound.toolPackages
      ++ lib.optionals cfg.agentBrowser.enable agentBrowser.packages;
    home.sessionVariables =
      lib.optionalAttrs cfg.enableAgentBaseline agent.env
      // lib.optionalAttrs cfg.agentBrowser.enable agentBrowser.env;
    home.file.".claude/settings.json" = {
      source = ../../../agents/claude/templates/settings-portable.json;
      force = compatibility;
    };
    home.file.".claude/CLAUDE.md" = {
      source = ../../../agents/shared/templates/caveman-lite-context.md;
      force = compatibility;
    };
    home.file.".codex/config.toml" = {
      source = ../../../agents/codex/templates/config-portable.toml;
      force = compatibility;
    };
    home.file.".codex/AGENTS.md" = {
      text = builtins.readFile ../../../agents/shared/templates/caveman-lite-context.md
        + lib.optionalString compoundCodexEnabled "\n\n${compound.codexAgentsBlock}";
      force = compatibility;
    };
    home.file.".config/opencode/opencode.json" = {
      source = ../../../agents/opencode/templates/opencode.json;
      force = compatibility;
    };
    home.file.".config/amp/settings.json" = {
      source = ../../../agents/amp/templates/settings.json;
      force = compatibility;
    };
    home.file.".pi/agent/settings.json" = {
      source = ../../../agents/pi-coding-agent/templates/settings.json;
      force = compatibility;
    };
    home.file.".pi/agent/keybindings.json" = {
      source = ../../../agents/pi-coding-agent/templates/keybindings.json;
      force = compatibility;
    };
    home.file.".pi/agent/AGENTS.md" = {
      source = ../../../agents/shared/templates/caveman-lite-context.md;
      force = compatibility;
    };
    home.file.".pi/agent/extensions/qna.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/qna.ts;
      force = compatibility;
    };
    home.file.".pi/agent/extensions/ask-user.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/ask-user.ts;
      force = compatibility;
    };
    home.file.".pi/agent/extensions/loop.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/loop.ts;
      force = compatibility;
    };
    home.file.".pi/agent/extensions/login-url-padding.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/login-url-padding.ts;
      force = compatibility;
    };
    home.file.".agents/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = agent.managedAmpSkillTree;
      force = compatibility;
    };
    home.file.".claude/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = claudeManagedSkillTree;
      force = compatibility;
    };
    home.file.".claude/agents" = lib.mkIf compoundClaudeEnabled {
      source = compound.managedClaudeAgentTree;
      force = compatibility;
    };
    home.file.".config/opencode/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = opencodeManagedSkillTree;
      force = compatibility;
    };
    home.file.".config/opencode/agents" = lib.mkIf compoundOpenCodeEnabled {
      source = compound.managedOpenCodeAgentTree;
      force = compatibility;
    };
    home.file.".codex/skills/compound-engineering" = lib.mkIf compoundCodexSkillsEnabled {
      source = compound.managedCodexSkillTree;
      force = compatibility;
    };
    home.file.".codex/skills/matt-pocock" = lib.mkIf cfg.enableAgentBaseline {
      source = agent.mkManagedSkillTree "toolnix-managed-codex-matt-pocock-skills" agent.mattPocockSkillLinks;
      force = compatibility;
    };
    home.file.".codex/skills/antithesis" = lib.mkIf cfg.enableAgentBaseline {
      source = agent.mkManagedSkillTree "toolnix-managed-codex-antithesis-skills" agent.antithesisSkillLinks;
      force = compatibility;
    };
    home.file.".codex/agents/compound-engineering" = lib.mkIf compoundCodexEnabled {
      source = compound.managedCodexAgentTree;
      force = compatibility;
    };
    home.file.".config/amp/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = ampManagedSkillTree;
      force = compatibility;
    };
    home.file.".pi/agent/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = managedSkillTree;
      force = compatibility;
    };
    home.file.".pi/agent/agents" = lib.mkIf compoundPiEnabled {
      source = compound.managedAgentTree;
      force = compatibility;
    };
    home.file.".pi/agent/extensions/subagent" = lib.mkIf (compoundPiEnabled && cfg.compoundEngineering.pi.subagentExtension.enable) {
      source = compound.piSubagentExtension;
      force = compatibility;
    };
  };
}
