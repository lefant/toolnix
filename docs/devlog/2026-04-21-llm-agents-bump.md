---
date: 2026-04-21
status: ✅ COMPLETED
related_issues: []
---

# Implementation Log - 2026-04-21

**Implementation**: Bumped the pinned `llm-agents` input so `toolnix` resolves the latest tracked coding-agent CLIs

## Summary

Updated `toolnix` to the latest `github:numtide/llm-agents.nix` revision and aligned the matching `llm-agents`-related entries in `devenv.lock`. No module wiring changed; the existing `modules/shared/agent-baseline.nix` and wrapped-tool exports already consume the pinned `llm-agents` package set.

## Plan vs Reality

**What was planned:**
- [ ] Refresh `toolnix` to the latest upstream `llm-agents` revision
- [ ] Keep the change limited to lockfile updates
- [ ] Verify the self-hosted host build and shell still work
- [ ] Record the update in a repo devlog

**What was actually implemented:**
- [x] Updated the `llm-agents` entry in `flake.lock`
- [x] Updated the transitive `blueprint` and `nixpkgs` entries in `flake.lock`
- [x] Aligned `devenv.lock` for `llm-agents`, `blueprint`, `bun2nix`, and `nixpkgs`
- [x] Verified the Home Manager activation build, `devenv` shell smoke test, and wrapped `pi` version
- [x] Wrote this devlog entry

## What changed

Changed:

- `flake.lock`
- `devenv.lock`
- `docs/devlog/2026-04-21-llm-agents-bump.md`

Updated `llm-agents` in `flake.lock`:

- `65ee6fc49bacd8c965ab0107d50d81e510af7488`
- -> `92de4ace99ea70a24146f7c2b71ff65e4ce358a8`

Aligned the same `llm-agents` revision in `devenv.lock`:

- `4814adf48100a2138b02591e6a7e000c106887b1`
- -> `92de4ace99ea70a24146f7c2b71ff65e4ce358a8`

This also advanced the related lock entries for:

- `llm-agents/blueprint`
- `llm-agents/nixpkgs`
- `llm-agents/bun2nix` in `devenv.lock`

## Verified versions

After the lock update, the repo resolves these tracked agent versions:

- `claude-code`: `2.1.116`
- `codex`: `0.122.0`
- `beads`: `1.0.2`
- `opencode`: `1.14.19`
- `pi`: `0.68.0`
- `amp`: `0.0.1776731460-g98fe19`

## Verification

Verified with:

```bash
nix flake update llm-agents
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
nix run .#toolnix-pi -- --version
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux."claude-code".version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.codex.version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.pi.version'
```

The Home Manager build fetched the updated agent binaries from `https://cache.numtide.com`, including:

- `claude-code-2.1.116`
- `codex-0.122.0`
- `pi-0.68.0`
- `opencode-1.14.19`
- `amp-0.0.1776731460-g98fe19`
- `beads-1.0.2`

## Challenges & Solutions

**Challenges encountered:**
- `toolnix` maintains both `flake.lock` and `devenv.lock`, so the `llm-agents` bump needed to stay aligned across both files.
- `devenv.lock` was on an older `llm-agents` revision than `flake.lock`, so a straight `flake.lock` update was not enough to keep repo-local lock state coherent.

**Solutions found:**
- Refreshed `flake.lock` from the upstream GitHub input.
- Mirrored the matching `llm-agents`-related nodes into `devenv.lock` so both lockfiles now agree on the agent package source revision.

## Learnings

- The current agent baseline remains cheap to maintain: once upstream `llm-agents` advances, `toolnix` usually only needs a lock bump.
- The wrapped `toolnix-pi` proof continues to be a useful fast verification path after agent bumps.

## Notes

- No source module changes were required.
- `devenv shell -- true` passed, but printed an unrelated notice that the installed `devenv` CLI (`2.0.6`) is newer than the lockfile input (`2.0.5`). This maintenance pass left that out of scope.
