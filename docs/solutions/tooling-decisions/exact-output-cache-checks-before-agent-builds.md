---
title: Exact-output cache checks before expensive agent builds
date: 2026-10-25
category: tooling-decisions
module: toolnix agent package baseline
problem_type: tooling_decision
component: tooling
severity: medium
applies_when:
  - "Checking whether a Nix-packaged agent can be substituted from a binary cache"
  - "Overriding the Nixpkgs input used by an upstream package flake"
  - "Explaining why the same agent version is cached upstream but builds locally"
tags: [nix, cache, llm-agents, codex, nixpkgs, dependency-pins]
---

# Exact-output cache checks before expensive agent builds

## Context

An active repository, a fresh package recipe, and an available upstream executable
do not establish substitution for the Nix output a consumer requests.

The [2026-10-25 Codex investigation](../../research/2026-10-25-codex-packaging-and-update-cadence.md)
reproduced a roughly 200-minute local build's output identity by changing an input
without changing the Codex version. The standalone llm-agents package was cached;
the version built against the source thread's followed Nixpkgs input was not.
The reproduction was an investigation fixture, not a change to this checkout.

## Guidance

1. Inspect the effective input graph, including both consumer lockfiles. Do not
   assume an upstream flake uses the consumer's Nixpkgs, or that matching top-level
   revisions imply matching transitive inputs.
2. Evaluate exact `drvPath` and `outPath` for each target with import-from-derivation
   disabled and lockfile writes disabled. If evaluation requires a build, stop
   rather than relaxing the guard.
3. Compare the baseline and proposed overrides without editing tracked files.
   Avoid a global Nixpkgs `follows` solely to deduplicate inputs: it can replace
   the graph used to produce upstream substitutes.
4. Check cache trust/configuration separately from exact-output availability.
   HTTP 200 for a `.narinfo` is discovery evidence, not signature verification or
   proof that every runtime reference is downloadable. Inspect a complete dry run
   against trusted caches. A locally present path can mask a remote cache miss.
5. If substantial source builds appear, stop and ask the owner before proceeding,
   including retries. A download-only realization can use `nix copy --from` with
   the evaluated output: it fetches or fails, but cannot compile a replacement.

Record the date, platform, full pins, override graph, output paths, cache responses,
and dry-run outcome. Recipe freshness, substitution, and runtime/security suitability
are separate checks. Neither metadata nor a fetch-only dry run reconstructs
historical cache publication lag or guarantees future availability.

## Why This Matters

The Codex recipe did not become stale when its input changed. Nix requested a
different output. Rebuilding that output locally was not evidence that upstream
lacked binaries or that all llm-agents Codex packages were uncached.

Preserving the upstream package's cached graph can avoid a heavy build, but it is
a dependency-policy choice, not a universal rule. If a dependency replacement is
required, budget and approve the rebuild or choose another verified cached package.
Do not silently weaken the required dependency policy just to obtain a substitute.

## When to Apply

- Before expensive agent builds, dependency refreshes, or Nixpkgs overrides.
- When an unchanged agent version appears cached elsewhere but builds locally.
- When comparing Linux and Apple Silicon outputs; probe each platform separately.

## Examples

This fixture reproduces the dated Codex identity comparison without modifying
Toolnix's lockfiles or building packages:

```bash
ref=github:numtide/llm-agents.nix/53a2d94ce3b88753200be9a0549d8978b031fa60
replacement=github:NixOS/nixpkgs/17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09
system=x86_64-linux

nix eval --option allow-import-from-derivation false \
  --no-write-lock-file --json \
  --apply 'p: { drvPath = p.drvPath; outPath = p.outPath; }' \
  "$ref#packages.$system.codex"

nix eval --option allow-import-from-derivation false \
  --no-write-lock-file --override-input nixpkgs "$replacement" --json \
  --apply 'p: { drvPath = p.drvPath; outPath = p.outPath; }' \
  "$ref#packages.$system.codex"

nix build --dry-run --no-link --option allow-import-from-derivation false \
  --no-write-lock-file "$ref#packages.$system.codex"

nix build --dry-run --no-link --option allow-import-from-derivation false \
  --no-write-lock-file --override-input nixpkgs "$replacement" \
  "$ref#packages.$system.codex"
```

Use daemon-trusted caches and keys before interpreting substitution results. The
fixture does not itself configure Numtide trust; see the
[cache bootstrap reference](../../specs/llm-agents-cache-bootstrap.md).

The observed x86_64 Linux output paths differed:

```text
Standalone upstream input graph; available from Numtide:
/nix/store/16f481b2zzvyvr2ycw51sm51b3f0508f-codex-0.164.0

Overridden Nixpkgs input; absent from both checked caches:
/nix/store/vzk46914vb6wbgscnc2s97gh9s2xh457-codex-0.164.0
```

Those cache results are dated observations, not guarantees for a later run.
The broader research record owns cadence, packaging, TLS, and daemon comparisons;
this learning does not authorize enabling Codex or switching its package owner.

Related guidance remains distinct:

- [Targeted llm-agents lock refreshes](targeted-llm-agents-lock-refreshes-2026-05-06.md)
  covers alignment of both lockfiles, not proof of cache availability.
- [Cache-friendly browser repacking](nix-browser-tool-cache-friendly-repack-2026-05-05.md)
  preserves a cached payload while changing runtime binding. It is not evidence
  that arbitrary Codex behavior can be changed with a wrapper.
