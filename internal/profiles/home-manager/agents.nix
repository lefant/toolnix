{ config, lib, pkgs, inputs, toolnixFeatures, ... }:
let
  features = toolnixFeatures;
  cfg = config.toolnix;
  agent = features.agentBaseline.data { inherit pkgs lib inputs; };
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
  config = {
    home.packages =
      lib.optionals cfg.enableAgentBaseline agent.packages
      ++ lib.optionals compoundToolsEnabled compound.toolPackages;
    home.sessionVariables =
      lib.optionalAttrs cfg.enableAgentBaseline agent.env;
    home.file.".claude/settings.json" = {
      source = ../../../agents/claude/templates/settings-portable.json;
      force = true;
    };
    home.file.".claude/CLAUDE.md" = {
      source = ../../../agents/shared/templates/caveman-lite-context.md;
      force = true;
    };
    home.file.".codex/config.toml" = {
      source = ../../../agents/codex/templates/config-portable.toml;
      force = true;
    };
    home.file.".codex/AGENTS.md" = {
      text = builtins.readFile ../../../agents/shared/templates/caveman-lite-context.md
        + lib.optionalString compoundCodexEnabled "\n\n${compound.codexAgentsBlock}";
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
    home.file.".pi/agent/extensions/ask-user.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/ask-user.ts;
      force = true;
    };
    home.file.".pi/agent/extensions/loop.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/loop.ts;
      force = true;
    };
    home.file.".pi/agent/extensions/login-url-padding.ts" = {
      source = ../../../agents/pi-coding-agent/extensions/login-url-padding.ts;
      force = true;
    };
    home.file.".agents/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = agent.managedAmpSkillTree;
      force = true;
    };
    home.file.".claude/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = claudeManagedSkillTree;
      force = true;
    };
    home.file.".claude/agents" = lib.mkIf compoundClaudeEnabled {
      source = compound.managedClaudeAgentTree;
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
    home.file.".codex/skills/compound-engineering" = lib.mkIf compoundCodexSkillsEnabled {
      source = compound.managedCodexSkillTree;
      force = true;
    };
    home.file.".codex/skills/matt-pocock" = lib.mkIf cfg.enableAgentBaseline {
      source = agent.mkManagedSkillTree "toolnix-managed-codex-matt-pocock-skills" agent.mattPocockSkillLinks;
      force = true;
    };
    home.file.".codex/skills/antithesis" = lib.mkIf cfg.enableAgentBaseline {
      source = agent.mkManagedSkillTree "toolnix-managed-codex-antithesis-skills" agent.antithesisSkillLinks;
      force = true;
    };
    home.file.".codex/agents/compound-engineering" = lib.mkIf compoundCodexEnabled {
      source = compound.managedCodexAgentTree;
      force = true;
    };
    home.file.".config/amp/skills" = lib.mkIf cfg.enableAgentBaseline {
      source = ampManagedSkillTree;
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
  };
}
