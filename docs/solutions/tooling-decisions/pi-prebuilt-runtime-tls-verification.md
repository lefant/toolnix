---
title: Verify the Exact Prebuilt Runtime Before Selecting a TLS Fix
date: 2026-10-25
category: tooling-decisions
module: toolnix agent package baseline
problem_type: tooling_decision
component: tooling
severity: high
applies_when:
  - "A standalone agent embeds a runtime with a TLS security fix"
  - "An upstream prebuilt or cache substitute might avoid a large local build"
  - "The same package version exists in several runtime or distribution variants"
tags: [pi, bun, nodejs, tls, security, nix, cache, prebuilt]
---

# Verify the Exact Prebuilt Runtime Before Selecting a TLS Fix

## Context

The [2026-10-25 Pi investigation](../../research/2026-10-25-pi-prebuilt-emudhra-tls.md)
asked whether an upstream prebuilt could replace a local Bun 1.4.4 compilation
without losing eMudhra incident rejection. It established a viable prebuilt
npm/Node runtime combination, not a completed Toolnix packaging change.

Pi 1.4.0 did not identify one runtime: its official standalone Linux binary
embedded Bun 1.3.14, while the source thread reported a Nix build with Bun 1.4.2.
The npm distribution used a separately selected Node runtime. A newer workflow
on upstream main did not mean that the published release assets had changed.

## Guidance

1. **Separate application version, embedded runtime, and packaging origin.**
   Record the exact archive URL/hash or Nix output path. Query compiled Bun
   directly rather than trusting `pi --version`:

   ```bash
   env -i HOME="$isolated_home" PATH=/usr/bin:/bin BUN_BE_BUN=1 \
     "$extracted_pi" --eval 'console.log(JSON.stringify(process.versions))'
   ```

   For a Node distribution, query the exact Node executable that the final
   wrapper will use. A foreign-architecture binary-string inspection is useful
   evidence, but is not equivalent to executing it.

2. **Test the failing cases and healthy controls through the same runtime.**
   Exercise both `fetch` and `node:https` when both APIs matter. Preserve exact
   error codes and HTTP responses, including No-CT cases. Missing issuer errors,
   revocation errors, timeouts, and accepted requests are different outcomes.
   Rejection is not persuasive when healthy traffic also fails.

3. **Actively check contradictory distribution results.** In this investigation,
   official Node 24.21.0 accepted seven incident endpoints, but the exact cached
   root-pinned Nix Node 24.21.0 rejected all 14 with issuer-chain errors; both
   passed the healthy controls. Do not call the latter vulnerable based on the
   former, or infer a revocation mechanism from the shared version number.
   Official and cached Nix Node 22.23.4 instead consistently reported
   `CERT_REVOKED` on all 14 and HTTP 200 on both controls.

4. **Check binaries and cache alternatives before authorizing compilation.**
   A custom output's cache miss does not imply that an upstream binary or
   supported npm distribution is unavailable. Inspect release channels,
   dependency locks, target-platform coverage, and native payloads. Prefer
   `nix copy` for a known substitute and `nix build --dry-run --no-link` to inspect
   realization requirements. Ask the owner before a large source build or retry.

5. **Validate package completeness independently of runtime TLS.** In the Pi
   probe, npm Pi with cached Node 22 loaded the managed settings, extensions, and
   a representative skill, but its native clipboard helper needed `libxcb`.
   Passing TLS and `--version` did not prove a complete Nix package. Keep native
   helper loading, wrapped startup, resource lookup, and representative skill
   discovery in the acceptance checks.

6. **Keep selection and rollout separate from research.** A successful isolated
   runtime probe supports a candidate, not an activation. Share one selected Pi
   package across the baseline, wrapper, and subagent example lookup when a
   later implementation is authorized. Preserve credential and state ownership.

## Why This Matters

Changing only a version label can retain the unsafe embedded runtime. Conversely,
discarding a distribution because another build with the same label failed can
cause an unnecessary expensive rebuild. The reliable unit of evidence is an
exact artifact plus its executed failure/control matrix and packaging checks.

Hashes establish which bytes were tested; they do not by themselves establish
publisher identity, attestation verification, or bit-reproducibility. Similarly,
an ARM cache entry establishes availability, not ARM runtime behavior. State each
verification limit explicitly so a future rollout does not inherit a stronger
claim than the research supports.

## When to Apply

Use this process for bundled-runtime agent updates, TLS incident response, and
cache-friendly package selection. Recheck release snapshots as upstream changes;
the Pi 1.4.0 findings are dated evidence, not permanent version-selection policy.

## Examples

The promising Pi candidate reused the pinned llm-agents recipe's supported Node
branch, rather than introducing a complete replacement derivation:

```nix
llmAgentsPkgs.pi.override {
  useBun = false;
  buildNpmPackage = pkgs.buildNpmPackage.override {
    nodejs = pkgs.nodejs_22;
  };
}
```

This expression was evaluated with the root Nixpkgs pin identified in the
research, and its dependencies were available as substitutes. The Pi output was
not built. Linux native-library fixup and cross-platform package verification
remain necessary; do not treat this snippet as a ready-to-activate solution.

For the wrapper contract, inspect `flake-parts/wrapped-tools.nix`; for resource
lookup, inspect `modules/shared/compound-engineering.nix`. Those owners already
encode managed-file seeding and the compiled/npm subagent-example layouts.

## Related

- [Full investigation and raw evidence](../../research/2026-10-25-pi-prebuilt-emudhra-tls.md).
- [Cache-friendly browser-tool repacking](nix-browser-tool-cache-friendly-repack-2026-05-05.md)
  covers a different runtime-binding problem; it does not establish that a
  compiled runtime can safely be replaced by patching paths.
- [Wrapped Pi stale symlinks](../integration-issues/wrapped-toolnix-pi-stale-symlinks-2026-05-04.md)
  explains why startup does not replace an existing valid settings symlink.
