{ pkgs, lib, inputs }:
let
  toolnixRoot = ../..;
  toolnixFlake = builtins.getFlake (toString toolnixRoot);
  resolvedInputs =
    if inputs ? "agent-skills" && inputs ? "llm-agents"
    then inputs
    else toolnixFlake.devenvSources // { toolnix = toolnixFlake; };

  agentSkillsInput = resolvedInputs."agent-skills";
  agentSkillsPath =
    if builtins.isAttrs agentSkillsInput && agentSkillsInput ? outPath
    then agentSkillsInput.outPath
    else agentSkillsInput;

  dirNames = dir:
    lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));

  rawSkillLinks =
    (map (name: {
      inherit name;
      path = "${agentSkillsPath}/lefant/${name}";
    }) (dirNames "${agentSkillsPath}/lefant")) ++
    lib.concatMap
      (org:
        map (name: {
          inherit name;
          path = "${agentSkillsPath}/vendor/${org}/${name}";
        }) (dirNames "${agentSkillsPath}/vendor/${org}"))
      (dirNames "${agentSkillsPath}/vendor");

  dedupeSkillLinks = links:
    lib.mapAttrsToList
      (name: path: { inherit name path; })
      (lib.foldl'
        (acc: item:
          if builtins.hasAttr item.name acc then
            acc
          else
            acc // { "${item.name}" = item.path; })
        {}
        links);

  dedupedSkillLinks = dedupeSkillLinks rawSkillLinks;

  mkManagedSkillTree = name: skillLinks: pkgs.linkFarm name
    (map (item: { name = item.name; path = item.path; }) skillLinks);

  managedSkillTree = mkManagedSkillTree "toolnix-managed-skills" dedupedSkillLinks;

  # Amp also discovers ~/.agents/skills. Filter before deduplication so a
  # non-plugin skill with the same name remains available in Amp's shared tree.
  ampSkillLinks = dedupeSkillLinks (builtins.filter
    (item: !(lib.hasPrefix "${agentSkillsPath}/vendor/mattpocock/" item.path)
      && !(lib.hasPrefix "${agentSkillsPath}/vendor/antithesishq/" item.path))
    rawSkillLinks);
  managedAmpSkillTree = mkManagedSkillTree "toolnix-managed-amp-baseline-skills"
    ampSkillLinks;
  mattPocockSkillLinks = builtins.filter
    (item: lib.hasPrefix "${agentSkillsPath}/vendor/mattpocock/" item.path)
    dedupedSkillLinks;
  antithesisSkillLinks = builtins.filter
    (item: lib.hasPrefix "${agentSkillsPath}/vendor/antithesishq/" item.path)
    dedupedSkillLinks;

  toolnixClaudeStatusline = pkgs.writeShellScriptBin "toolnix-claude-statusline" ''
    toolnix_root="''${TOOLNIX_SOURCE_DIR:-${toolnixRoot}}"
    exec "$toolnix_root/agents/claude/scripts/statusline.sh" "$@"
  '';
in
{
  inherit managedSkillTree managedAmpSkillTree mkManagedSkillTree ampSkillLinks mattPocockSkillLinks antithesisSkillLinks;
  skillLinks = dedupedSkillLinks;

  packages =
    [ toolnixClaudeStatusline ]
    ++ (with resolvedInputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      claude-code
      codex
      opencode
      pi
      amp
    ]);

  env = {
    CODEX_CHECK_FOR_UPDATE_ON_STARTUP = "false";
    DISABLE_AUTOUPDATER = "1";
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
    AMP_SKIP_UPDATE_CHECK = "1";
  };
}
