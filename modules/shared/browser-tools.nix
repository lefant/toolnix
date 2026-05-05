{ pkgs, lib, inputs }:
let
  toolnixRoot = ../..;
  toolnixFlake = builtins.getFlake (toString toolnixRoot);
  resolvedInputs =
    if inputs ? "llm-agents"
    then inputs
    else toolnixFlake.devenvSources // { toolnix = toolnixFlake; };

  llmAgentsInput = resolvedInputs."llm-agents";
  llmAgentsPath =
    if builtins.isAttrs llmAgentsInput && llmAgentsInput ? outPath
    then llmAgentsInput.outPath
    else llmAgentsInput;

  chromium = pkgs.chromium;
  chromiumExecutable = "${chromium}/bin/chromium";
  system = pkgs.stdenv.hostPlatform.system;
  llmAgentsPackages =
    if builtins.isAttrs llmAgentsInput
      && llmAgentsInput ? packages
      && builtins.hasAttr system llmAgentsInput.packages
    then llmAgentsInput.packages.${system}
    else { };
  upstreamAgentBrowserPackage =
    if llmAgentsPackages ? agent-browser
    then llmAgentsPackages.agent-browser
    else pkgs.callPackage "${llmAgentsPath}/packages/agent-browser/package.nix" { };
  # Use the cached llm-agents package output as the source payload, but do not
  # expose it directly: upstream wraps it to llm-agents' Chromium. Copy and patch
  # the executable/share payload so this output only points at Toolnix Chromium.
  agentBrowserPackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "agent-browser";
    version = upstreamAgentBrowserPackage.version or "0.26.0";
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.python3
    ];
    dontUnpack = true;
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"
      cp ${upstreamAgentBrowserPackage}/bin/.agent-browser-wrapped "$out/bin/.agent-browser-wrapped"
      cp -R ${upstreamAgentBrowserPackage}/share "$out/share"
      chmod u+w "$out/bin/.agent-browser-wrapped"
      chmod +x "$out/bin/.agent-browser-wrapped"

      python3 - <<'PY'
import os
from pathlib import Path
old = b"${upstreamAgentBrowserPackage}"
new = os.environ["out"].encode()
if len(old) != len(new):
    raise SystemExit(f"store path length mismatch: {len(old)} != {len(new)}")
path = Path(os.environ["out"]) / "bin/.agent-browser-wrapped"
data = path.read_bytes()
if old not in data:
    raise SystemExit("upstream package path not found in agent-browser binary")
path.write_bytes(data.replace(old, new))
PY

      makeWrapper "$out/bin/.agent-browser-wrapped" "$out/bin/agent-browser" \
        --set AGENT_BROWSER_EXECUTABLE_PATH ${lib.escapeShellArg chromiumExecutable}

      runHook postInstall
    '';
  };
  vhsPackage = pkgs.vhs.override {
    inherit chromium;
  };

  browserEnv = {
    AGENT_BROWSER_EXECUTABLE_PATH = chromiumExecutable;
    AGENT_BROWSER_STATE_DIR = "$HOME/.agent-browser";
    TOOLNIX_CHROMIUM = chromiumExecutable;
    CHROMIUM_BIN = chromiumExecutable;
    CHROME_BIN = chromiumExecutable;
    PUPPETEER_EXECUTABLE_PATH = chromiumExecutable;
  };
in {
  inherit chromium chromiumExecutable agentBrowserPackage vhsPackage browserEnv;

  agentBrowser = {
    packages = [ agentBrowserPackage ];
    env = browserEnv;
    docs = {
      install = ''
        agent-browser --version
      '';
    };
  };

  browserTools = {
    packages = [
      vhsPackage
      chromium
    ];
    env = browserEnv;
    docs = {
      install = ''
        agent-browser --version
        vhs --version
        chromium --version
      '';
    };
  };
}
