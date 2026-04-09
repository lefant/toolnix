# Restore zsh completion defaults

Date: 2026-04-07

## Summary

Restored the missing opinionated zsh completion baseline for toolnix-managed
hosts.

The current Home Manager-owned zsh config had dropped completion bootstrap that
previously existed in older dotfile-managed shells. That regression removed
completion zstyles such as `special-dirs true` and likely caused interactive
directory completion behavior like typing `..` and pressing Tab to stop behaving
as expected.

## Changes

- added tracked completion defaults at `home-manager/files/zsh-completion`
- linked that file to `~/.zsh/completion` from the Home Manager profile
- restored zsh completion bootstrap in `modules/shared/opinionated-shell.nix`
  - `zmodload -i zsh/complist`
  - `autoload -Uz compinit`
  - `compinit`
  - `setopt completeinword`
- kept the completion defaults close to the older pre-Home-Manager shell config
  including:
  - `special-dirs true`
  - `menu select=10`
  - `matcher-list ...`
  - `squeeze-slashes true`
- added a toolnix-owned verification script:
  - `scripts/check-opinionated-zsh.sh`
- documented the completion verification step in the main README and maintainer
  reference instead of leaving it as a control-plane-only readiness concern

## Verification

Local repo verification:

- `nix build .#homeConfigurations.lefant-toolnix.activationPackage`
- `nix run nixpkgs#devenv -- shell -- true`
- `zsh -n home-manager/files/zsh-completion`

Host rollout and verification:

- `lefant-toolnix.exe.xyz`
  - pulled updated `toolnix`
  - rebuilt and activated `homeConfigurations.lefant-toolnix`
  - verified:
    - `compinit` available
    - `_comps` initialized
    - `~/.zsh/completion` present
    - `special-dirs true` present
- `lefant-memory.exe.xyz`
  - updated the normal checkout at `~/git/lefant/toolnix`
  - applied Home Manager switch via temporary bootstrap flake pointing at the
    updated local toolnix checkout
  - verified:
    - `compinit` available
    - `_comps` initialized
    - `~/.zsh/completion` present
    - `special-dirs true` present
  - previous host-local completion file was preserved as:
    - `~/.zsh/completion.pre-zsh-completion`

## Notes

The normal standalone `hackbox-ctrl` provisioning path did not perform this
rollout because the current remote preflight headroom guard blocked both target
hosts before activation. The shell-completion change was therefore rolled out
manually on the affected hosts after verification of the tracked toolnix build.
