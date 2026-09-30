---
date: 2026-09-30
status: ✅ COMPLETED
---

# Refresh Codex and agent CLIs

## Outcome

Updated `llm-agents` in both `flake.lock` and `devenv.lock` to
[`af40d966`](https://github.com/numtide/llm-agents.nix/commit/af40d966859ec4075ecc172dbb39e53f474dc5d9).
Only that input and its private Nixpkgs dependency changed. Toolnix's primary
Nixpkgs, agent skills, and plugin inputs remain unchanged.

| Package | Previous | Updated |
| --- | --- | --- |
| Codex | 0.155.1 | 0.159.2 |
| Claude Code | 2.1.278 | 2.1.285 |
| Amp | 0.0.1790064360-g301b53 | 0.0.1790712063-gb89205 |
| Pi | 0.87.0 | 0.99.1 |
| OpenCode | 1.18.32 | 1.18.33 |
| Beads | 1.3.0 | unchanged |
| agent-browser | 0.38.1 | unchanged |

## Codex packaging

The [current CLI documentation](https://learn.chatgpt.com/docs/codex/cli)
recommends a standalone installer and still supports npm. The npm registry's
`latest` version was 0.159.2 during this check.

Toolnix already includes Codex in its shared Home Manager/devenv agent baseline.
The pinned [upstream Nix package](https://github.com/numtide/llm-agents.nix/blob/af40d966859ec4075ecc172dbb39e53f474dc5d9/packages/codex/package.nix)
builds the upstream Rust release, including `codex-code-mode-host`, and provides
the Linux sandbox support and runtime wrapper. It does not run the standalone
installer. No Toolnix package override or imperative installation is necessary.

## Verification

- `nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage --no-link`: passed; updated agents fetched from Numtide's cache.
- `devenv shell -- bash -c 'for cli in codex claude amp pi opencode bd agent-browser; do "$cli" --version || exit; done'`: passed; all seven commands reported the expected versions.
- `nix --accept-flake-config flake check --no-build`: passed evaluation; this does not execute the check derivations. Nix reported derivation-context warnings for `options.json` and unchecked custom flake outputs.
- `codex features list` with a disposable `CODEX_HOME` containing the tracked configuration: passed. The CLI warned that it would not create helper aliases under `/tmp`; this check validates configuration parsing, not sandbox execution.
- `git diff --check`: passed.
- No new unit tests: this is a generated dependency-pin refresh, verified through the real package build and CLI startup checks.
- Code review: skipped (mechanical diff). Only dependency pins and this implementation record changed.

The activation package was built, not activated. Authenticated model calls and
host rollout were not tested. Devenv reported that its installed CLI is newer
than its own locked input; that unrelated input was deliberately left unchanged.
