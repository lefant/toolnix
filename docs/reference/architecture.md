# Toolnix Architecture

This document describes the intended steady-state architecture for `toolnix` as a self-hosted Nix-first development environment and shared module repo.

For the ongoing migration away from the previous imperative runtime setup hook, see:

- [`docs/plans/2026-03-28-remove-imperative-setup-hook.md`](../plans/2026-03-28-remove-imperative-setup-hook.md)

## Flake Outputs

`flake.nix` exposes three primary interfaces:

- `homeConfigurations.lefant-toolnix`
  - self-hosted Home Manager configuration for the current toolnix host
- `homeManagerModules.default`
  - reusable Home Manager module export for toolnix host configuration
- `devenvModules.default`
  - reusable `devenv` module export for project shells

## Module Layering

`toolnix` is structured around shared layers in `modules/shared/`:

- `required-baseline.nix`
  - mandatory baseline packages and locale environment
- `opinionated-shell.nix`
  - interactive shell defaults such as aliases, tmux helpers, and shell ergonomics
- `agent-baseline.nix`
  - shared AI-agent tool packages and managed skill tree inputs
- `agent-browser.nix`
  - optional host-native browser automation support
- `host-control.nix`
  - optional control-host helpers kept outside the main baseline

These layers are assembled in two main entry modules:

- `modules/home-manager/toolnix-host.nix`
  - Home Manager host environment
- `modules/devenv/default.nix`
  - project and self-hosted `devenv` shell environment

## Host vs Project Responsibilities

### Home Manager host

The Home Manager host module owns persistent user-facing shell and tool configuration, including:

- shell and tmux config
- git and SSH config
- persistent agent config files under `$HOME`
- shared skill directory wiring
- session-level environment variables

### Project / self-hosted devenv shell

The `devenv` module owns project-shell concerns, including:

- packages available in the shell
- shell-local environment variables
- interactive aliases and helper functions
- optional project-shell features such as `agent-browser`

`devenv` is intended to shape the active shell environment, not to perform persistent home-directory provisioning.

## Optional Features

### Opinionated shell layer

The project-shell path exposes toggleable opinionated features under `toolnix.opinionated.*`, with a top-level enable/disable switch.

### Agent browser

`agent-browser` is opt-in for both host and project contexts through:

- `toolnix.agentBrowser.enable = true;`

It provides a host-native wrapper and stores runtime state in user-local paths.

### Host control helpers

Host-control behavior is isolated behind:

- `toolnix.enableHostControl = true;`

This keeps control-host inventory workflows outside the default toolnix environment.

## State Locations

### Declarative repo-managed sources

Tracked sources live in this repo under:

- `agents/`
- `modules/`
- `home-manager/files/`
- `docs/`

### Persistent user state

Persistent user state lives under `$HOME`, including:

- shell dotfiles managed by Home Manager
- agent configuration under locations such as `~/.claude/`, `~/.codex/`, `~/.config/opencode/`, `~/.config/amp/`, `~/.openclaw/`, and `~/.pi/agent/`
- shared user skills under `~/.agents/skills`
- browser automation state under `~/.agent-browser` and related cache/prefix directories when `agent-browser` is enabled

## Notes

This document is intentionally minimal while the setup-hook migration is still in progress. Runtime migration details and sequencing belong in the linked plan until the migration is complete.
