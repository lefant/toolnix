{ pkgs }:
let
  nodejs = pkgs.nodejs_22;
  npm = pkgs.nodePackages.npm;
  version = "0.22.3";
  wrapper = pkgs.writeShellScriptBin "agent-browser" ''
    set -euo pipefail

    export AGENT_BROWSER_NPM_PREFIX="''${AGENT_BROWSER_NPM_PREFIX:-$HOME/.local/share/toolnix/agent-browser/npm-prefix}"
    export AGENT_BROWSER_NPM_CACHE="''${AGENT_BROWSER_NPM_CACHE:-$HOME/.cache/toolnix-agent-browser/npm}"
    export AGENT_BROWSER_STATE_DIR="''${AGENT_BROWSER_STATE_DIR:-$HOME/.agent-browser}"
    export npm_config_prefix="$AGENT_BROWSER_NPM_PREFIX"
    export npm_config_cache="$AGENT_BROWSER_NPM_CACHE"
    export PATH="${nodejs}/bin:${npm}/bin:$AGENT_BROWSER_NPM_PREFIX/bin:$PATH"

    real="$AGENT_BROWSER_NPM_PREFIX/bin/agent-browser"
    version_file="$AGENT_BROWSER_NPM_PREFIX/.toolnix-agent-browser-version"

    mkdir -p "$AGENT_BROWSER_NPM_PREFIX" "$AGENT_BROWSER_NPM_CACHE" "$AGENT_BROWSER_STATE_DIR"

    if [ ! -x "$real" ] || [ ! -f "$version_file" ] || [ "$(cat "$version_file")" != "${version}" ]; then
      "${npm}/bin/npm" install -g "agent-browser@${version}"
      printf '%s\n' "${version}" > "$version_file"
    fi

    exec "$real" "$@"
  '';
in {
  packages = [ wrapper ];

  env = {
    AGENT_BROWSER_STATE_DIR = "$HOME/.agent-browser";
    AGENT_BROWSER_NPM_PREFIX = "$HOME/.local/share/toolnix/agent-browser/npm-prefix";
    AGENT_BROWSER_NPM_CACHE = "$HOME/.cache/toolnix-agent-browser/npm";
  };

  docs = {
    install = ''
      agent-browser --version
      agent-browser install
    '';
  };
}
