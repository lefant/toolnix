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

  dedupedSkillLinks =
    lib.mapAttrsToList
      (name: path: { inherit name path; })
      (lib.foldl'
        (acc: item:
          if builtins.hasAttr item.name acc then
            acc
          else
            acc // { "${item.name}" = item.path; })
        {}
        rawSkillLinks);

  managedSkillTree = pkgs.linkFarm "toolnix-managed-skills"
    (map (item: { name = item.name; path = item.path; }) dedupedSkillLinks);

  toolnixClaudeStatusline = pkgs.writeShellScriptBin "toolnix-claude-statusline" ''
    toolnix_root="''${TOOLNIX_SOURCE_DIR:-${toolnixRoot}}"
    exec "$toolnix_root/agents/claude/scripts/statusline.sh" "$@"
  '';
in
{
  inherit managedSkillTree;

  packages =
    [ toolnixClaudeStatusline ]
    ++ (with resolvedInputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      claude-code
      codex
      beads
      opencode
      pi
      amp
    ]);

  env = {
    BEADS_NO_DAEMON = "1";
    CODEX_CHECK_FOR_UPDATE_ON_STARTUP = "false";
    DISABLE_AUTOUPDATER = "1";
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
    AMP_SKIP_UPDATE_CHECK = "1";
  };
}
