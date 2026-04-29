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

  skillLinks = map (name: {
    inherit name;
    path = "${piAssets}/skills/${name}";
  }) skillNames;

  agentLinks = map (sourceName: {
    name = "${normalizeName sourceName}.md";
    path = "${piAssets}/agents/${normalizeName sourceName}.md";
  }) agentSourceNames;

  managedSkillTree = pkgs.linkFarm "toolnix-compound-engineering-skills"
    (map (item: { name = item.name; path = item.path; }) skillLinks);

  managedAgentTree = pkgs.linkFarm "toolnix-compound-engineering-pi-agents"
    (map (item: { name = item.name; path = item.path; }) agentLinks);

  system = pkgs.stdenv.hostPlatform.system;
  piPackage = resolvedInputs.llm-agents.packages.${system}.pi;
  piSubagentExtension = "${piPackage}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/subagent";
in
{
  inherit
    agentLinks
    compoundSource
    managedAgentTree
    managedSkillTree
    piAssets
    piSubagentExtension
    pluginRoot
    skillLinks;
}
