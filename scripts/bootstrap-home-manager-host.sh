#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '\n==> %s\n' "$1"
}

warn() {
  printf '\nWARNING: %s\n' "$1" >&2
}

usage() {
  cat <<'EOF'
Usage:
  scripts/bootstrap-home-manager-host.sh [options]

Bootstrap a fresh machine into the published toolnix Home Manager host state
without requiring a target-side toolnix git clone.

Options:
  --toolnix-ref <ref>         Flake ref for toolnix (default: github:lefant/toolnix)
  --host-name <name>          toolnix.hostName value (default: hostname -s)
  --home-username <name>      Home Manager username (default: current user)
  --home-directory <path>     Home Manager home directory (default: $HOME)
  --state-version <version>   Home Manager state version (default: 25.05)
  --enable-host-control       Enable toolnix.enableHostControl
  --disable-agent-baseline    Disable toolnix.enableAgentBaseline
  --enable-agent-browser      Enable toolnix.agentBrowser.enable
  --bootstrap-dir <path>      Bootstrap working dir (default: ~/.local/share/toolnix-bootstrap)
  --backup-extension <ext>    Home Manager backup extension (default: backup)
  --skip-cache-config         Do not attempt machine-local Nix cache configuration
  --help                      Show this help

Notes:
- On fresh exeuntu VMs with Determinate multi-user Nix, machine-local cache
  configuration is still needed for the Numtide cache.
- Credentials remain machine-local and are not managed by this script.
EOF
}

TOOLNIX_REF="github:lefant/toolnix"
HOST_NAME="$(hostname -s 2>/dev/null || echo toolnix)"
HOME_USERNAME="$(id -un)"
HOME_DIRECTORY="$HOME"
STATE_VERSION="25.05"
ENABLE_HOST_CONTROL=false
ENABLE_AGENT_BASELINE=true
ENABLE_AGENT_BROWSER=false
BOOTSTRAP_DIR="$HOME/.local/share/toolnix-bootstrap"
BACKUP_EXTENSION="backup"
SKIP_CACHE_CONFIG=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --toolnix-ref)
      TOOLNIX_REF="$2"
      shift 2
      ;;
    --host-name)
      HOST_NAME="$2"
      shift 2
      ;;
    --home-username)
      HOME_USERNAME="$2"
      shift 2
      ;;
    --home-directory)
      HOME_DIRECTORY="$2"
      shift 2
      ;;
    --state-version)
      STATE_VERSION="$2"
      shift 2
      ;;
    --enable-host-control)
      ENABLE_HOST_CONTROL=true
      shift
      ;;
    --disable-agent-baseline)
      ENABLE_AGENT_BASELINE=false
      shift
      ;;
    --enable-agent-browser)
      ENABLE_AGENT_BROWSER=true
      shift
      ;;
    --bootstrap-dir)
      BOOTSTRAP_DIR="$2"
      shift 2
      ;;
    --backup-extension)
      BACKUP_EXTENSION="$2"
      shift 2
      ;;
    --skip-cache-config)
      SKIP_CACHE_CONFIG=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

bool_to_nix() {
  case "$1" in
    true) printf 'true\n' ;;
    false) printf 'false\n' ;;
    *) echo "ERROR: expected true/false, got: $1" >&2; exit 1 ;;
  esac
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    return 0
  fi

  log "Installing Nix"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
}

load_nix() {
  if command -v nix >/dev/null 2>&1; then
    return 0
  fi

  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  if ! command -v nix >/dev/null 2>&1; then
    echo "ERROR: nix is not available after installation/bootstrap" >&2
    exit 1
  fi
}

configure_cache() {
  if [ "$SKIP_CACHE_CONFIG" = true ]; then
    warn "Skipping machine-local cache configuration by request"
    return 0
  fi

  local cache_block
  cache_block=$(cat <<'EOF'
extra-substituters = https://cache.numtide.com
extra-trusted-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
EOF
)

  if [ -w /etc/nix ] || sudo -n true >/dev/null 2>&1; then
    log "Configuring machine-local Nix cache settings"
    sudo mkdir -p /etc/nix
    sudo tee /etc/nix/nix.custom.conf >/dev/null <<<"$cache_block"
  else
    warn "Could not write /etc/nix/nix.custom.conf automatically; continuing with existing machine config"
  fi
}

render_bootstrap_flake() {
  log "Rendering bootstrap flake in $BOOTSTRAP_DIR"
  mkdir -p "$BOOTSTRAP_DIR"

  cat > "$BOOTSTRAP_DIR/flake.nix" <<EOF
{
  description = "toolnix host bootstrap";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    toolnix.url = "${TOOLNIX_REF}";
    nixpkgs.follows = "toolnix/nixpkgs";
    home-manager.follows = "toolnix/home-manager";
  };

  outputs = { nixpkgs, home-manager, toolnix, ... }:
    let
      system = "x86_64-linux";
    in {
      homeConfigurations.bootstrap = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [
          toolnix.homeManagerModules.default
          {
            home.username = "${HOME_USERNAME}";
            home.homeDirectory = "${HOME_DIRECTORY}";
            home.stateVersion = "${STATE_VERSION}";

            toolnix.hostName = "${HOST_NAME}";
            toolnix.enableHostControl = $(bool_to_nix "$ENABLE_HOST_CONTROL");
            toolnix.enableAgentBaseline = $(bool_to_nix "$ENABLE_AGENT_BASELINE");
            toolnix.agentBrowser.enable = $(bool_to_nix "$ENABLE_AGENT_BROWSER");
          }
        ];
      };
    };
}
EOF
}

run_bootstrap() {
  log "Applying Home Manager bootstrap"
  nix run --accept-flake-config github:nix-community/home-manager -- \
    switch -b "$BACKUP_EXTENSION" --flake "$BOOTSTRAP_DIR#bootstrap"
}

print_readiness_summary() {
  log "Bootstrap readiness summary"
  command -v claude || true
  command -v pi || true
  ls -l "$HOME_DIRECTORY/.claude/settings.json" || true
  ls -l "$HOME_DIRECTORY/.claude/skills" || true
  ls -l "$HOME_DIRECTORY/.pi/agent/settings.json" || true
}

ensure_nix
load_nix
configure_cache
load_nix
render_bootstrap_flake
run_bootstrap
print_readiness_summary
