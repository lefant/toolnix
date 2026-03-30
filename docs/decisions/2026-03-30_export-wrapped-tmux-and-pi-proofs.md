# Export wrapped tmux and pi proofs from toolnix

## Date

2026-03-30

## Status

accepted

## Context

With the flake-parts and dendritic refactors complete, the next question was whether `toolnix` should expose portable single-command tools in addition to Home Manager and `devenv` integration.

The strongest initial candidates were:

- `tmux`, because it has no auth dependency and a clearly tracked config shape
- `pi`, because it supports config-dir overrides and interactive `/login`

## Decision

`toolnix` exports wrapped proof commands for:

- `toolnix-tmux`
- `toolnix-pi`

These are additive portability proofs, not replacements for Home Manager or `devenv`.

Wrapped pi reuses existing local auth state when available by linking wrapped `auth.json` to `~/.pi/agent/auth.json`; otherwise first-run auth via `/login` remains acceptable.

## Consequences

`toolnix` now has a proven portable command path for tmux and for starting a pi session with tracked config and skills from a fresh repo checkout.

This keeps secret ownership local and avoids embedding credentials in Nix, but it also means wrapped auth remains intentionally machine-local rather than fully declarative.
