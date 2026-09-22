---
date: 2026-09-22
status: ✅ COMPLETED
---

# Coding agent package refresh

Updated `llm-agents` in both `flake.lock` and `devenv.lock` to the September 22 upstream revision, including its required bun2nix and nixpkgs updates. Other inputs remain unchanged.

| Package | Previous | Updated |
| --- | --- | --- |
| Amp | 0.0.1789329654-g2cdf19 | 0.0.1790064360-g301b53 |
| Claude Code | 2.1.270 | 2.1.278 |
| Codex | 0.154.0 | 0.155.1 |
| OpenCode | 1.18.30 | 1.18.32 |
| Pi | 0.85.1 | 0.87.0 |
| Beads | 1.2.2 | 1.3.0 |
| agent-browser | 0.37.1 | 0.38.1 |

## Verification

- `nix --accept-flake-config flake check --no-build --no-eval-cache`: passed.
- `nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage --no-link`: passed; no activation performed.
- `devenv shell -- true`: passed.
- Built Amp binary `--version`: `0.0.1790064360-g301b53`.
- `git diff --check`: passed.

Code review: skipped (mechanical diff). Only dependency locks and this record changed; no new tests were needed.

## Limits

At verification time, npm listed Amp `0.0.1790082161-g365795`, newer than the latest llm-agents package. This refresh retains the existing Nix package source and cache rather than introducing a custom Amp override. A future llm-agents refresh can pick up that build.

Nix reported derivation-context warnings for `options.json` and restricted cache-key settings, but evaluation and the build succeeded. Devenv reported its installed CLI is newer than the separately pinned devenv input; that unrelated input was left unchanged.

No changes were pushed or activated on a host.
