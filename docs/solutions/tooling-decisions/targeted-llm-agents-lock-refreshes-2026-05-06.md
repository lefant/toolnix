---
title: Targeted llm-agents Lock Refreshes Across Toolnix Locks
date: 2026-05-06
category: tooling-decisions
module: toolnix agent package baseline
problem_type: tooling_decision
component: tooling
severity: medium
applies_when:
  - "The upstream numtide/llm-agents.nix input has advanced"
  - "Toolnix needs newer tracked agent CLI packages without changing module wiring"
  - "Both flake.lock and devenv.lock are present in the repo"
related_components:
  - Home Manager agent baseline
  - devenv project shell
  - wrapped toolnix-pi proof
  - Numtide binary cache
  - llm-agents transitive inputs
tags:
  - llm-agents
  - flake-lock
  - devenv-lock
  - nix
  - agent-baseline
  - cache
---

# Targeted llm-agents Lock Refreshes Across Toolnix Locks

## Context

Toolnix sources its tracked coding-agent CLI set from `github:numtide/llm-agents.nix`. When that upstream input advances, the normal maintenance path should be a targeted lock refresh rather than a module rewrite: the existing agent baseline, Home Manager profile, devenv profile, and wrapped-tool exports already consume the pinned package set.

The May 2026 refresh started as a `flake.lock` update from `6b4673fddbbe1f2656b3fa8d2a32666570aafbfa` to a newer upstream revision and passed `nix flake check --no-build`. Follow-up inspection showed the repo also keeps `devenv.lock`; prior llm-agents devlogs document that both lockfiles should remain aligned when this input changes. The final refresh therefore updated both `flake.lock` and `devenv.lock` to `646ae209744976acee0c2c0eda0de7a68abbf015` and accepted the matching transitive changes.

Session history and devlogs show the same recurring maintenance pattern: previous llm-agents bumps were mostly lock-only changes, but older passes explicitly aligned `devenv.lock` and used wrapped `toolnix-pi`, Home Manager, or devenv smoke checks when the change affected runtime agent versions (session history).

## Guidance

For routine `llm-agents` upkeep in Toolnix, treat the upstream input as the source of the agent package baseline and refresh it directly in every tracked lockfile that records the input.

Use the non-deprecated targeted flake command:

```bash
nix flake update llm-agents
```

Then align the devenv lock when `devenv.lock` exists:

```bash
devenv update llm-agents
```

Check both lockfiles for the same upstream `llm-agents` revision:

```bash
rg -n '"llm-agents"|"rev"' flake.lock devenv.lock
```

For the May 2026 refresh, the expected final state was:

```text
llm-agents rev: 646ae209744976acee0c2c0eda0de7a68abbf015
```

Accept transitive lock changes owned by `llm-agents` when they come from upstream input graph changes. In this refresh that included:

- `llm-agents/bun2nix`
- `llm-agents/flake-parts`
- `llm-agents/nixpkgs`
- `llm-agents/treefmt-nix` in `devenv.lock`
- removal of the no-longer-referenced `llm-agents/bun2nix/import-tree` node

Do not edit Toolnix module wiring unless the upstream package interface changed or a verification step proves the existing consumers no longer evaluate.

## Why This Matters

A flake-only bump can look complete because `nix flake check --no-build` evaluates the Nix flake outputs successfully. But Toolnix also tracks a `devenv.lock`; leaving that lock on the old `llm-agents` graph creates split-brain maintenance state for project-shell consumers and future agents reading repo history.

Keeping the two locks aligned makes the maintenance invariant simple: one upstream agent package revision describes the Toolnix baseline for both flake and devenv paths. It also keeps transitive graph removals, such as the dropped `import-tree` node, consistent across lockfiles.

The Numtide cache warnings seen during verification are expected in this untrusted-user exe.dev setup when Nix reports restricted settings. The important signal is that the cache settings are available through saved trusted settings and evaluation completes without falling back into heavy source builds.

## When to Apply

- When `llm-agents` has a new upstream revision and Toolnix should pick up newer packaged agent CLIs.
- When refreshing agent defaults, wrapped `toolnix-pi`, or browser tooling that depends on the `llm-agents` package set.
- When a lock refresh removes or changes transitive `llm-agents` inputs.
- When a previous bump touched only one lockfile and `devenv.lock` still references the old revision.

## Examples

Minimal maintenance flow:

```bash
nix flake update llm-agents
devenv update llm-agents
nix flake check --no-build
```

Useful revision check:

```bash
jq -r '.nodes["llm-agents"].locked.rev' flake.lock
jq -r '.nodes["llm-agents"].locked.rev' devenv.lock
```

Expected result after an aligned refresh:

```text
646ae209744976acee0c2c0eda0de7a68abbf015
646ae209744976acee0c2c0eda0de7a68abbf015
```

If the refresh is more than lock maintenance, expand verification based on what changed:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
nix run .#toolnix-pi -- --version
```

Those heavier checks are useful when the update changes runtime agent versions, templates, or wrapped-tool behavior. For a pure evaluation-only lock refresh, `nix flake check --no-build` is the minimum gate.

## Related

- `docs/devlog/2026-05-06-llm-agents-bump.md` — current aligned refresh outcome.
- `docs/devlog/2026-04-21-llm-agents-bump.md` — prior example where `flake.lock` and `devenv.lock` alignment was explicitly required.
- `docs/devlog/2026-04-25-llm-agents-pi-bump-and-gpt-5.5-defaults.md` — example where a lock bump combined with template default changes needed heavier verification.
- `docs/reference/maintaining-toolnix.md` — maintenance reference for the `llm-agents.nix` input and Numtide cache requirement.
- `docs/specs/llm-agents-cache-bootstrap.md` — cache/bootstrap requirements for avoiding expensive source builds.
