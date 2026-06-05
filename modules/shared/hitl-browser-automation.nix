{ pkgs, lib, inputs }:
let
  toolnixRoot = ../..;
  toolnixFlake = builtins.getFlake (toString toolnixRoot);
  resolvedInputs =
    if inputs ? "agent-skills" && inputs ? "llm-agents"
    then inputs
    else toolnixFlake.devenvSources // { toolnix = toolnixFlake; };

  browserToolsData = import ./browser-tools.nix { inherit pkgs lib; inputs = resolvedInputs; };

  agentSkillsInput = resolvedInputs."agent-skills";
  agentSkillsPath =
    if builtins.isAttrs agentSkillsInput && agentSkillsInput ? outPath
    then agentSkillsInput.outPath
    else agentSkillsInput;

  skillPath = "${agentSkillsPath}/lefant/hitl-browser-automation";
  skillCommand = "${skillPath}/scripts/hitl-browser-hub";

  hitlBrowserHub = pkgs.writeShellScriptBin "hitl-browser-hub" ''
    skill_command=${lib.escapeShellArg skillCommand}
    if [ ! -x "$skill_command" ]; then
      echo "missing hitl-browser-automation skill command: $skill_command" >&2
      echo "Update Toolnix's agent-skills input to a revision that contains lefant/hitl-browser-automation." >&2
      exit 2
    fi
    exec ${pkgs.bash}/bin/bash "$skill_command" "$@"
  '';

  vncPackages = with pkgs; [
    tigervnc
    fluxbox
  ];
in {
  inherit hitlBrowserHub skillPath skillCommand vncPackages;
  inherit (browserToolsData) chromium chromiumExecutable agentBrowserPackage browserEnv;

  packages = [
    hitlBrowserHub
    pkgs.nodejs
    pkgs.python3
    pkgs.jq
    pkgs.curl
  ] ++ vncPackages;

  env = browserToolsData.browserEnv;

  docs = {
    install = ''
      hitl-browser-hub check
    '';
  };
}
