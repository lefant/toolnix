---
date: 2026-10-25
status: ✅ COMPLETED
related_research: docs/research/2026-10-25-trust-update-recovery.md
---

# Trust-update recovery and verification

## Delivery boundary

Reconstructed the inaccessible trust-update thread's final behavior from its
export and surviving research. This is not an exact restoration of its lost
commit or uncommitted tree. Implementation and Linux verification are complete
in both the recovery orb and a fresh orb. The owner authorized committing,
pushing, and merging the recovery after that fresh-orb check. Host activation
and re-enablement remain unapproved; the Toolnix rollout hold remains in place.

The [recovery research](../research/2026-10-25-trust-update-recovery.md) owns the
historical evidence and decisions. This log records newly executed checks, not
the lost thread's reported successes. The existing weekly browser-readiness
review remains enabled; no duplicate schedule was created.

## Reconstructed behavior and pins

- Codex is disabled indefinitely: no CLI, preference wrapper, or shell alias.
  Existing settings, skills, credentials, and history are retained.
- Agent-browser, browserTools, and dependent HITL opt-ins are accepted no-ops.
  They add neither packages nor environment variables, including when combined.
- Pi remains the llm-agents recipe, bundled with fixed-source upstream Bun 1.4.4
  binaries for Linux x64 and Apple Silicon. Bun itself is not compiled.
- Both lockfiles use direct Nixpkgs
  [17dd0b7](https://github.com/NixOS/nixpkgs/commit/17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09),
  exposing NSS cacert 3.131.1. The llm-agents input follows that Nixpkgs source at
  [53a2d94](https://github.com/numtide/llm-agents.nix/commit/53a2d94ce3b88753200be9a0549d8978b031fa60).
- Both lockfiles include the requested agent-skills update to
  [a492605](https://github.com/lefant/agent-skills/commit/a4926054d71d022c466ae2fb00f3c5431b71eaae).
  Its four-file diff changes RPI documentation from `recording-dev-notes` to
  `record-dev-notes`; vendored MP and Antithesis trees are unchanged. The MP
  reviewed-revision guard was advanced after that comparison.
- Compound Engineering retains its existing
  [15ab6f7](https://github.com/EveryInc/compound-engineering-plugin/commit/15ab6f76bb0bcf7fd4de0e8cba369c1c70ad5d82)
  pin. A broad refresh reached 36 upstream skills and failed Toolnix's reviewed
  33-skill export contract. That unrelated upgrade was excluded rather than
  changing the export contract during trust recovery.

## Fresh Linux evidence

Dry-run plans were inspected before realization. Large dependencies came from
caches; agent binaries were repackaged from upstream artifacts. Pi bundling and
the small `formatelf` helper built locally. No large source build was started.

| Check | Newly observed result |
| --- | --- |
| `nix flake check --accept-flake-config --no-write-lock-file` | All 13 Linux checks pass, including plugin exports, adoption, preserved agent settings, and browser opt-in no-ops. |
| `nix build --accept-flake-config --no-write-lock-file --no-link .#toolnix-pi .#homeConfigurations.lefant-toolnix.activationPackage` | Both build; activation was not run. |
| Home Manager runtime closure and `home-path/bin` | No Codex, agent-browser, Chromium, `vhs`, or HITL hub executable. Dormant Codex config and MP skill files remain. |
| Wrapped Pi RPC, isolated temporary HOME, offline startup | Pi 1.4.0; `qna`, `loop`, and 121 skills discovered without authenticated inference. |
| Extension executed inside rebuilt Pi, isolated HOME and environment | Embedded Bun reports 1.4.4. Both `fetch` and `node:https` reject all 14 incident endpoints with `CERT_REVOKED`. Each API also completes four healthy-control requests with HTTP 200. |
| Python/OpenSSL with the resolved NSS 3.131.1 bundle explicitly selected | All 14 incident endpoints fail certificate verification; four healthy-control requests return HTTP 200. Errors identify rejected certificates or unavailable issuers, not DNS/timeouts. |
| Cached devenv 2.4.0, guarded shell evaluation and screened shell build | Clean project shell starts, runs Pi 1.4.0 and curl, and contributes no browser environment. Healthy HTTPS request succeeds. |
| `git diff --check` | Passes. |

The 14 incident hosts include the No-CT variants. Healthy controls use the
advisory origin and `example.com`, with additional `example.com` requests before
and after the incident list. Raw fresh probe exports are retained locally as
`restored-pi-tls-probe.json` and `restored-ca-tls-probe.json`, separate from the
recovered historical exports; they are not tracked source files.

The profile assertions read generated settings during evaluation. An initial
IFD-disabled check stopped there. The exact JSON generators were inspected and
realized separately (two small formatting derivations); ordinary full-check
evaluation then passed. Pi's example-extension lookup also refers to the already
built Pi output. This does not justify allowing unknown evaluation-time builds.

## Cold-orb repeat before publication

The [fresh verification orb](https://ampcode.com/threads/T-01a17275-689d-713c-82b2-cb4e592deedb)
started with Nix 2.35.3, 67 store paths (113 MiB), no devenv, and no Toolnix build
outputs. It tested the supplied implementation patch against
[f70bbc1](https://github.com/lefant/toolnix/commit/f70bbc18d6c2bab8e0a56c2c1fff8e13423274e1),
not a warm project snapshot. The input archive's SHA-256 was
`173f0dd5f4fca7ad5c967090082680ab857bd72203b153a936e6eea14c0c6aac`.

All 13 Linux check derivations built, Home Manager built without activation,
and Pi discovery, Pi TLS, explicit CA-bundle TLS, disabled-runtime checks, and
the real clean devenv smoke passed again. All browser opt-ins together left
the package list and declarative environment unchanged. Large dependencies came
from caches; no large source compilation was needed. The implementation patch,
both locks, and supplied documents were unchanged by testing. Only this devlog
was subsequently extended to record the result before publication.

The probe harness initially left RPC stdin open; closing it and rerunning
completed normally. No product fix was needed. Evidence, exact output paths,
build logs, and reproduction scripts are retained in the local review artifact
`toolnix-fresh-orb-verification.tgz`, SHA-256
`fe285329f26da12f0b24737c1f85ef6038bcbe40721838e1771f92c3a0a39225`.

## Limits that remain relevant to rollout

- Darwin Pi and portable browser-disable derivations evaluate. No Darwin build,
  runtime/TLS probe, native runner PATH check, adoption, or activation was done.
- The resolved Nix CA bundle and Pi's embedded verifier are verified separately.
  A clean devenv shell exports neither `SSL_CERT_FILE` nor `NIX_SSL_CERT_FILE`;
  curl reports OpenSSL default trust paths. The initial smoke-test assumptions
  about those variables were wrong. The shell smoke is not proof that every
  shell program selects Toolnix's bundle, and this change does not add a global
  trust-store override or modify the host's trust store.
- Claude, Amp, OpenCode, forced bundled-Node CA mode, native host trust stores,
  and separately installed browser/agent copies were not freshly TLS-tested.
  Removing Toolnix packages does not stop old processes or remove other installs.
- Authenticated inference was not exercised. Browser automation remains paused;
  the scheduled review does not authorize re-enablement.
- Future large source builds and host activation still require explicit owner
  approval; publishing this recovery does not authorize deployment. The reusable
  [exact-output/cache guidance](../solutions/tooling-decisions/exact-output-cache-checks-before-agent-builds.md)
  remains applicable; successful local builds do not guarantee future cache hits.
