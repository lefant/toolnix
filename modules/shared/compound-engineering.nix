{ pkgs, lib, inputs }:
let
  toolnixRoot = ../..;
  toolnixFlake = builtins.getFlake (toString toolnixRoot);
  resolvedInputs =
    if inputs ? "compound-engineering-plugin" && inputs ? "llm-agents"
    then inputs
    else toolnixFlake.devenvSources // { toolnix = toolnixFlake; };

  compoundInput = resolvedInputs."compound-engineering-plugin";
  compoundSource =
    if builtins.isAttrs compoundInput && compoundInput ? outPath
    then compoundInput.outPath
    else compoundInput;

  pluginRoot = "${compoundSource}/plugins/compound-engineering";
  sourceSkillsDir = "${pluginRoot}/skills";
  sourceAgentsDir = "${pluginRoot}/agents";

  dirNames = dir:
    lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));

  fileNames = dir:
    lib.attrNames (lib.filterAttrs (_: type: type == "regular" || type == "symlink") (builtins.readDir dir));

  skillNames =
    lib.filter
      (name: builtins.pathExists "${sourceSkillsDir}/${name}/SKILL.md")
      (dirNames sourceSkillsDir);

  skillSupportsPlatform = platform: name:
    let
      content = builtins.readFile "${sourceSkillsDir}/${name}/SKILL.md";
      platformLine = lib.findFirst
        (line: lib.hasPrefix "ce_platforms:" (lib.trim line))
        null
        (lib.splitString "\n" content);
    in platformLine == null || lib.hasInfix platform platformLine;

  opencodeSkillNames = lib.filter (skillSupportsPlatform "opencode") skillNames;

  agentSourceNames =
    lib.filter
      (name: lib.hasSuffix ".agent.md" name || lib.hasSuffix ".md" name)
      (fileNames sourceAgentsDir);

  normalizeName = name:
    let
      lower = lib.toLower name;
      replaced = builtins.replaceStrings [ ".agent.md" ".md" ":" " " "_" "/" "\\" ] [ "" "" "-" "-" "-" "-" "-" ] lower;
    in lib.removeSuffix "-" (lib.removePrefix "-" replaced);

  piAssets = pkgs.runCommand "compound-engineering-pi-assets" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python3 ${./compound-engineering/render-pi-assets.py} ${lib.escapeShellArg pluginRoot} "$out"
  '';

  opencodeAssets = pkgs.runCommand "compound-engineering-opencode-assets" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python3 ${./compound-engineering/render-opencode-assets.py} ${lib.escapeShellArg pluginRoot} "$out"
  '';

  codexAssets = pkgs.runCommand "compound-engineering-codex-assets" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python3 ${./compound-engineering/render-codex-assets.py} ${lib.escapeShellArg pluginRoot} "$out"
    OUT="$out" python3 - <<'PY'
import os
import pathlib
import tomllib
agent_dir = pathlib.Path(os.environ['OUT']) / 'agents' / 'compound-engineering'
agent_files = sorted(agent_dir.glob('*.toml'))
if not agent_files:
    raise SystemExit(f'no Codex agent TOML files rendered under {agent_dir}')
for path in agent_files:
    tomllib.loads(path.read_text(encoding='utf-8'))
PY
  '';

  rawSkillLinks = map (name: {
    inherit name;
    path = "${sourceSkillsDir}/${name}";
  }) skillNames;

  piSkillLinks = map (name: {
    inherit name;
    path = "${piAssets}/skills/${name}";
  }) skillNames;

  opencodeSkillLinks = map (name: {
    inherit name;
    path = "${opencodeAssets}/skills/${name}";
  }) opencodeSkillNames;

  agentLinks = map (sourceName: {
    name = "${normalizeName sourceName}.md";
    path = "${piAssets}/agents/${normalizeName sourceName}.md";
  }) agentSourceNames;

  opencodeAgentLinks = map (sourceName: {
    name = "${normalizeName sourceName}.md";
    path = "${opencodeAssets}/agents/${normalizeName sourceName}.md";
  }) agentSourceNames;

  rawAgentLinks = map (sourceName: {
    name = "${normalizeName sourceName}.md";
    path = "${sourceAgentsDir}/${sourceName}";
  }) agentSourceNames;

  managedSkillTree = pkgs.linkFarm "toolnix-compound-engineering-skills"
    (map (item: { name = item.name; path = item.path; }) piSkillLinks);

  managedAgentTree = pkgs.linkFarm "toolnix-compound-engineering-pi-agents"
    (map (item: { name = item.name; path = item.path; }) agentLinks);

  managedOpenCodeSkillTree = pkgs.linkFarm "toolnix-compound-engineering-opencode-skills"
    (map (item: { name = item.name; path = item.path; }) opencodeSkillLinks);

  managedOpenCodeAgentTree = pkgs.linkFarm "toolnix-compound-engineering-opencode-agents"
    (map (item: { name = item.name; path = item.path; }) opencodeAgentLinks);

  managedClaudeAgentTree = pkgs.linkFarm "toolnix-compound-engineering-claude-agents"
    (map (item: { name = item.name; path = item.path; }) rawAgentLinks);

  managedCodexSkillTree = "${codexAssets}/skills/compound-engineering";
  managedCodexAgentTree = "${codexAssets}/agents/compound-engineering";
  codexAgentsBlock = builtins.readFile ./compound-engineering/codex-agents-block.md;

  system = pkgs.stdenv.hostPlatform.system;
  piPackage = resolvedInputs.llm-agents.packages.${system}.pi;
  rawPiSubagentExtension = "${piPackage}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/subagent";
  piSubagentExtension = pkgs.runCommand "toolnix-patched-pi-subagent-extension" { } ''
    cp -R ${lib.escapeShellArg rawPiSubagentExtension} "$out"
    chmod -R u+w "$out"
    if [ -f "$out/index.ts" ]; then
      sed -i 's|from "typebox";|from "@sinclair/typebox";|' "$out/index.ts"
      sed -i "s|from 'typebox';|from '@sinclair/typebox';|" "$out/index.ts"
    fi
  '';
  toolPackages = with pkgs; [
    ast-grep
    silicon
  ];
in
{
  inherit
    agentLinks
    codexAgentsBlock
    codexAssets
    compoundSource
    managedAgentTree
    managedSkillTree
    managedClaudeAgentTree
    managedCodexAgentTree
    managedCodexSkillTree
    managedOpenCodeAgentTree
    managedOpenCodeSkillTree
    opencodeAgentLinks
    opencodeAssets
    opencodeSkillLinks
    piAssets
    piSkillLinks
    piSubagentExtension
    pluginRoot
    rawAgentLinks
    rawSkillLinks
    toolPackages;

  skillLinks = piSkillLinks;
}
