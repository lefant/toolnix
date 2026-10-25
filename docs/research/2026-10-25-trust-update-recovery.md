---
date: 2026-10-25
status: reconstructed
---

# Trust-update recovery: decisions and evidence boundaries

## What this record recovers

The original [trust-update thread](https://ampcode.com/threads/T-01a16d53-4e4e-70cc-88d7-8dde455d3cfe)
is inaccessible during recovery. The supplied text export reports a local commit
`930eb82b562b64229645ea6834cca67e4c9205d5` on `security/update-flake-inputs`,
followed by uncommitted decisions and edits. That commit/tree is unavailable.
This work reconstructs the final requested behavior; it is **not an exact tree
restoration**, and restoring that commit alone would not recover the later edits.

Evidence available for this record:

- The owner's supplied thread export, including the final disable/retain decisions.
- Recovered `recovered-pi-prebuilt-probes.json`,
  `recovered-pi-1.4.0-release-artifacts.json`, and
  `recovered-emudhra-browser-probes.json` from the 2026-10-25 investigation.
  Their records were inspected and counted during recovery; the probes were not
  rerun. The raw files remain local and are not part of this documentation change.
- The separately published [Codex packaging and update-cadence research](2026-10-25-codex-packaging-and-update-cadence.md),
  which remains the owner of those findings and is not replaced by this record.
- Recovery coordination's confirmation of the existing weekly browser schedule.

The source export reports all 13 Linux flake checks, a Home Manager build without
activation, and a devenv smoke check passing in the lost checkout. Those are
**historical reports, not test results for this reconstruction**. Likewise, its
runtime exports, closure verification, and TLS results cannot certify a newly
reconstructed output. Publication, activation, and large builds are not authorized
by this recovery. No private consuming-system configuration is reproduced here.

## Decisions to preserve

| Component | Recovered decision |
| --- | --- |
| Codex | Disabled indefinitely. Omit package, preference wrapper, and shell alias; preserve settings, skills, credentials, and history. No replacement, migration TODO, or re-enable date. |
| Pi | Retain the `llm-agents` recipe and bundle with **prebuilt Bun 1.4.4**. This is Pi packaging work, not compiling Bun. |
| Browser automation | Pause `agent-browser`, `browserTools`, and dependent HITL packages/environment. Existing `true` opt-ins remain accepted but are no-ops; preserve skills and user state. |
| Nix trust data | Recover the direct locked Nixpkgs source and NSS **3.131.1** CA-bundle update, with relevant inputs aligned in both lockfiles. Verify resolved contents, not merely moved pins. |
| Build policy | Inspect dry-run plans, exact outputs, cache trust, input alignment, and upstream prebuilts first. Ask explicit owner approval before any large source build or retry, even if it appears the only feasible choice. |

The [README build rule](../../README.md#build-approval) is also the agent rule:
`AGENTS.md` and `CLAUDE.md` are symlinks to that file. The
[maintainer diagnostic](../reference/maintaining-toolnix.md#binary-cache-note)
uses `nix build --dry-run`, not `nix run ... -- --help`, which can initiate builds.

Disabling a Toolnix package does not remove independently installed copies or
stop existing processes. Inspect actual runner PATHs before a future rollout.
Preserving Codex configuration is intentional; the portable profile still leaves
its active config writable and unmanaged, while the full profile retains its
existing managed config layout.

## Why the CA/input update was needed

The [eMudhra advisory](https://emudhra.we-have-a-problem.com/) supplied 14 incident
endpoint chains, including chains without Certificate Transparency (No-CT).
The source export reports that Toolnix's old NSS 3.126 trust data accepted 7/14
in offline verification, versus 0/14 with NSS 3.131.1. It also reports that an
override of the old Cachix compatibility flake's nested input did not affect the
CA bundle actually imported by that shim. The recovered direction is a direct
Nixpkgs input; verify the effective bundle through each consumer path.

The public investigation pins were
[Nixpkgs 17dd0b7](https://github.com/NixOS/nixpkgs/commit/17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09)
and [llm-agents 53a2d94](https://github.com/numtide/llm-agents.nix/commit/53a2d94ce3b88753200be9a0549d8978b031fa60).
These identify the investigation, not proof of any deployed host's revision.
Changing llm-agents' Nixpkgs input changes output identities and may lose its
upstream substitutes. The Codex research reproduced that distinction; an
uncached overridden output was not evidence that llm-agents lacked prebuilts.
Use the [exact-output cache procedure](../solutions/tooling-decisions/exact-output-cache-checks-before-agent-builds.md)
without weakening the dependency policy solely to regain a cache hit.

A consuming NixOS/nix-darwin system's `security.pki.caCertificateBlacklist` is
complementary to Toolnix, not a Home Manager responsibility or a replacement for
package updates. Host-native, embedded, browser, and shared trust stores each
need independent verification. Forced bundled-CA modes and custom CA settings
can differ from the default path. Updating a standalone Bun or Node package
does not replace a runtime already embedded in an agent executable.

## Pi: keep the moderate fix, not a new package migration

Recovered release metadata identifies upstream
[Pi v1.4.0](https://github.com/earendil-works/pi/releases/tag/v1.4.0), published
2026-10-21 at 22:49:48 UTC. It lists Linux, Darwin, and Windows standalone archives,
source/install manifests, and `SHA256SUMS`. The Linux x64 archive is 42,645,744
bytes; the Darwin ARM64 archive is 31,098,931 bytes. Asset existence and sizes
are not evidence that their embedded runtimes are fixed or that they were
executed on every platform.

The source export says that Pi's official standalone 1.4.0 embedded Bun 1.3.14,
despite the upstream build workflow having moved to Bun 1.4.4. The recovered
JSON includes a **separate Bun 1.3.14 runtime probe**, not executable-inspection
logs proving that embedding. It also records command discovery in official Pi
and npm/Node 22 runs, including `qna`, `loop`, and a skill. That is a narrow
compatibility check, not complete Pi integration or authenticated inference.

The runtime probe exercises both `fetch` and `node:https`, with the same result
counts for each API:

| Recorded runtime/configuration | Incident endpoints accepted | Healthy controls |
| --- | ---: | --- |
| Bun 1.3.14 | 7/14 | Both HTTP 200 |
| Nix Node 22.23.4, default and system-CA-labelled runs | 0/14; `CERT_REVOKED` | Both HTTP 200 |
| Nix Node 24.21.0, default and system-CA-labelled runs | 0/14; issuer unavailable | Both HTTP 200 |
| Official Node 22.23.4 and 26.12.1 | 0/14; `CERT_REVOKED` | Both HTTP 200 |
| Official Node 24.21.0 | 7/14 | Both HTTP 200 |

The controls were the advisory origin and `example.com`. These dated results
show why a newer major version or a similar version string is insufficient:
packaging and the selected trust store matter. The JSON labels do not preserve
every invocation/environment detail, so they are not a complete reproduction
recipe or a guarantee for forced bundled-CA mode.

The export reports that Pi rebuilt using
[prebuilt Bun 1.4.4](https://github.com/oven-sh/bun/releases/tag/bun-v1.4.4)
rejected all 14 incident endpoints. That fixed-Pi result is export-only evidence,
not a newly executed probe or a run contained in the recovered Pi JSON.
The owner chose to retain this moderate packaging fix through `llm-agents`.
The npm/Node alternative would still need native-library and Toolnix integration
work; it was not selected. No upstream fixed-standalone release date was known.

## Browser automation: two independent TLS paths

`agent-browser` mainly controls a separate browser, but also makes native
HTTPS/WSS connections for APIs and remote browser control. Chromium verifies
page navigation and subresources separately. Headless mode changes neither
that boundary nor the need to verify both paths.

The recovered browser JSON describes Linux x86-64 probes with disposable
profiles, no certificate bypass, and no host trust changes. The Chrome runs used
`--disable-component-update` and `--no-sandbox`; they were trust experiments,
not production sandbox or component-updater verification.

| Recorded browser configuration | Incident navigations accepted | Control |
| --- | ---: | --- |
| Chrome for Testing 156.0.8078.47 | 7/14 | Healthy before/after |
| Chrome for Testing 157.0.8103.15 | 7/14 | Healthy before/after |
| Google Chrome 156.0.8078.47 | 6/14 | Healthy before/after |
| Chrome for Testing 156 plus private NSS distrust database | 0/14 | Healthy before/after |
| Lightpanda 1.0.2 with the recorded system CA bundle | 0/14 | HTTP 200 healthy control |
| Lightpanda with old incident roots | 2/2 selected No-CT endpoints | Negative trust-store control |

Chrome's extra rejection was `ERR_CERTIFICATE_TRANSPARENCY_REQUIRED`, not proof
of complete incident revocation. The private NSS experiment distrusted 12
published intermediate certificate variants with `p,p,p`, not test leaf
certificates. Its notes report CRLSet sequence zero throughout and a partial
distrust negative control that changed only the targeted chains.

This demonstrates a possible Linux mitigation using a prebuilt browser, not a
ready Toolnix integration. Isolation, loading that fails closed, `--ca-cert`
compatibility, unknown future cross-certificates, and Darwin remain unverified.
Lightpanda used Debian `ca-certificates 20250419~deb12u2` in this experiment;
the old-root control shows it still needs appropriate trust data. Browser
fidelity is a separate concern. Neither alternative was selected for rollout.

The JSON notes also report that unmodified agent-browser 0.39.2 accepted a
No-CT endpoint on its native WSS path: an HTTP 200 response reached the WebSocket
handshake, proving TLS acceptance. This is a saved note, not a full native trace
in the JSON. The source export reports a patched native build rejecting all
14 endpoints, while Chromium remained exposed. Fixing only that CLI was therefore
insufficient, and the final owner decision was to pause the whole integration.

## Historical costs, not new build measurements

The export reports Linux runtime closures of approximately 187 MiB for fixed Pi,
651 MiB for the custom Codex build, and 1.73 GiB for the CLI/browser combination.
It reports roughly 200 minutes for the Codex source build. Pi bundling was
estimated at 1–10 minutes; that was not a measured build duration. These figures
do not describe current download sizes, peak build resources, or Darwin outputs.
They explain the decision to retain Pi while deferring unused integrations;
they are not approval to repeat the earlier builds.

## Weekly readiness review and remaining gates

Recovery coordination verified that the existing
[weekly browser review thread](https://ampcode.com/threads/T-01a171e9-4705-7527-bc49-54046be4baa6)
was still enabled, with next run **2026-11-01 at 08:10 UTC / 09:10 Stockholm**.
No duplicate schedule was created. The review asks whether an **unmodified**
agent-browser/browser setup is secure enough to propose re-enablement. It does
not authorize installation, activation, large builds, or automatic re-enablement.

Before any future re-enablement, assess the then-current exact package outputs
and substitutes; test native HTTPS/WSS and browser navigation with incident,
No-CT, and healthy controls; and verify Linux and Apple Silicon separately.
The scheduled research should report a recommendation for the owner's decision,
not silently adopt a private NSS patch or alternate browser backend.

Codex remains disabled regardless of that browser review. Its existing research
contains conditional future assessment criteria, not a migration commitment.
Fresh checks of the reconstructed tree are recorded separately in the
[recovery verification log](../devlog/2026-10-25-trust-update-recovery.md).
Neither those Linux checks nor the old reports establish Darwin execution,
deployed trust stores, or removal of independent installations.
