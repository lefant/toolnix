---
date: 2026-10-25
status: completed
---

# Codex packaging, runtime, and update cadence

## Decision and scope

The owner wants Codex disabled, with no planned re-enable date. This investigation
does not implement that decision, select a replacement package, or activate hosts.
The disabling work belongs to the separate
[security/update thread](https://ampcode.com/threads/T-01a16d53-4e4e-70cc-88d7-8dde455d3cfe).
Its unpublished checkout is not this research checkout's `main`.

Do not create an unconditional migration TODO. If the owner explicitly requests
re-enablement, start by assessing the then-current Nixpkgs `pkgs.codex`. It is a
reasonable first candidate for a daemon-off Toolnix baseline, not a settled future
choice. llm-agents remains credible when a store-resident daemon is required.

Research and probes were read-only with respect to Toolnix and hosts. No source
builds, authenticated model calls, package changes, or activation were performed.
Runtime probes used isolated HOME directories and either dummy local provider
settings or unauthenticated advisory endpoints. Temporary probe state was removed.
The [research thread](https://ampcode.com/threads/T-01a171e8-b0d6-7756-8683-ce74e7661f06)
contains the execution record.

## Inputs and evidence boundaries

The supplied investigation pins were:

- [llm-agents 53a2d94](https://github.com/numtide/llm-agents.nix/commit/53a2d94ce3b88753200be9a0549d8978b031fa60).
- [Nixpkgs 17dd0b7](https://github.com/NixOS/nixpkgs/commit/17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09).
- [Codex rust-v0.164.0](https://github.com/openai/codex/releases/tag/rust-v0.164.0),
  published 2026-10-23 at 04:48:10 UTC, source commit
  [6aaac69](https://github.com/openai/codex/commit/6aaac694803004a63c6f393d153c96d22521a6b9).

Unless stated otherwise, package behavior below refers to those exact pins, and
cache observations refer to 2026-10-25. They are not promises about later releases.

## Upstream prebuilts exist, but the CLI is not the whole package

The official release provides Linux musl and Apple Silicon CLI archives and full
`codex-package-*` archives. The earlier archive phase checked SHA-256 digests and
verified the Linux CLI/full-package Sigstore release identity against OpenAI's
release workflow and tag. Apple Silicon archive inspection is not an executed
Apple Silicon runtime test or a claim of equivalent signature verification.

The full package contains the CLI, code-mode helper, package metadata, ripgrep,
Linux bubblewrap, and voice runtime. For example, the release provides
`codex-package-x86_64-unknown-linux-musl.tar.gz` and
`codex-package-aarch64-apple-darwin.tar.gz`. Copying only the CLI omits runtime
companions and can change feature availability. The Linux full archive's voice
helper still requires a GNU glibc loader despite the package's musl target name.

A custom upstream-binary Nix package would need to maintain complete layout,
runtime dependencies, provenance checks, and platform handling. A wrapper cannot
reproduce llm-agents' Rust patch that keeps the daemon in the store. An upstream
release-channel installer/updater also introduces a second, writable installation
owner alongside Nix. Neither is the smallest maintenance route when an existing
Nix package is cached.

## Update cadence: both repositories were responsive

The eight-week sample is 2026-08-30 00:00 through 2026-10-25 00:00 UTC; the latest
four weeks begin 2026-09-27. Lag is upstream GitHub release `published_at` to the
package PR's `merged_at` on llm-agents `main` or Nixpkgs `master`.

| Measure | llm-agents | Nixpkgs |
| --- | ---: | ---: |
| Distinct version bumps merged in eight weeks | 23 | 17 |
| Median release-to-merge lag | 6.6 hours | 13.0 hours |
| Maximum lag | 29.1 hours | 57.7 hours |
| Version bumps merged in latest four weeks | 11 | 11 |
| Median lag in latest four weeks | 10.1 hours | 7.5 hours |

For the 15 versions common to both eight-week update samples, medians were 7.6
hours for llm-agents and 13.0 hours for Nixpkgs. Cadence alone therefore does not
justify a categorical switch: llm-agents was faster over the full sample, while
Nixpkgs was faster over the latest four weeks.

### Dated primary evidence

| Release | Published UTC | llm-agents merge UTC | Nixpkgs merge UTC |
| --- | --- | --- | --- |
| [0.163.0](https://github.com/openai/codex/releases/tag/rust-v0.163.0) | 2026-10-15 21:30:38 | [2026-10-16 00:51:54](https://github.com/numtide/llm-agents.nix/pull/10876) | [2026-10-17 03:40:51](https://github.com/NixOS/nixpkgs/pull/574657) |
| [0.164.0](https://github.com/openai/codex/releases/tag/rust-v0.164.0) | 2026-10-23 04:48:10 | [2026-10-24 09:54:30](https://github.com/numtide/llm-agents.nix/pull/11287) | [2026-10-23 20:22:18](https://github.com/NixOS/nixpkgs/pull/577857) |

llm-agents also committed an explicit
[webpki security backport on 2026-10-20](https://github.com/numtide/llm-agents.nix/commit/69d1f4621804d13b9658ff9ac9b2a151815132cb),
before the upstream 0.164.0 release. No analogous Codex-directory backport appeared
in the sampled Nixpkgs history. This is dependency-maintenance evidence, not proof
of every runtime TLS path. The pinned llm-agents
[update workflow](https://github.com/numtide/llm-agents.nix/blob/53a2d94ce3b88753200be9a0549d8978b031fa60/.github/workflows/update.yml)
schedules checks four times daily. Nixpkgs provides release-aware update scripts.

### Sampling and reproduction limits

- Counted Codex-directory version transitions, not general repository activity:
  [llm-agents history](https://github.com/numtide/llm-agents.nix/commits/53a2d94ce3b88753200be9a0549d8978b031fa60/packages/codex/)
  and [Nixpkgs history](https://github.com/NixOS/nixpkgs/commits/17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09/pkgs/by-name/co/codex/).
  Eight llm-agents and five Nixpkgs non-version path changes were excluded.
- Deduplicated Nixpkgs' 0.163.0 source commit and merge commit. Checked PR landing
  dates rather than treating commit timestamps as availability dates.
- A seven-day lookback caught Nixpkgs 0.151.0, authored on August 29 but
  [merged August 31](https://github.com/NixOS/nixpkgs/pull/557695). It belongs in
  the 17 updates and accounts for the 57.7-hour maximum.
- OpenAI published 26 stable Rust CLI releases inside the eight-week window.
  Python tags and prereleases were excluded. Some short-lived patches were
  skipped: the sample represents 23 of those releases for llm-agents and 16 for
  Nixpkgs, plus Nixpkgs' preceding 0.151.0 release. Unequal cohorts affect medians.
- Data came from GitHub's path-scoped commits API, associated-PR API, and stable
  release list. Start the commit search before the window, join version bumps to
  stable Rust release publication times, then filter by actual PR merge time.
- These are `main`/`master` recipe measurements, not stable-channel promotion,
  devenv-rolling availability, Toolnix lockfile uptake, or release-to-cache lag.
  Eight weeks of active maintenance do not establish a long-term SLA.

## Cache identity explains the expensive local build

An upstream release archive, a cached Nix-built package, and an updated Nix recipe
are different things. A recipe update does not establish substitute availability.
Dependency/input changes can produce a different store output at the same version.

The standalone llm-agents pin uses
[Nixpkgs f20cd90](https://github.com/NixOS/nixpkgs/commit/f20cd90e28fe0403873f473b29e42662cd86e8c4).
Its x86_64 Linux output was available from Numtide:

```text
/nix/store/16f481b2zzvyvr2ycw51sm51b3f0508f-codex-0.164.0
```

The source thread instead made llm-agents' Nixpkgs input follow Toolnix's supplied
17dd0b7 pin. Reproducing that override without writing a lockfile produced its exact
previously built output:

```text
/nix/store/vzk46914vb6wbgscnc2s97gh9s2xh457-codex-0.164.0
```

That output and its corresponding ARM64 Linux and Apple Silicon outputs returned
HTTP 404 from both Numtide and NixOS caches. This reproduces the input difference;
it is not a claim that the unpublished follows change exists in this checkout.
The source thread reported approximately 200 minutes for the earlier local build.
This research did not retry it.

| Exact package configuration | x86_64 Linux | ARM64 Linux | Apple Silicon |
| --- | --- | --- | --- |
| Standalone llm-agents, own locked Nixpkgs | Cached; fetch-only dry run | Cached; fetch-only dry run | Cached; fetch-only dry run |
| Nixpkgs 17dd0b7 `pkgs.codex` | Cached; runtime executed | Cached; fetch-only dry run | Cached; fetch-only dry run |
| llm-agents with Nixpkgs overridden to 17dd0b7 | Output absent from both caches | Output absent from both caches | Output absent from both caches |

The initial Nixpkgs Linux dry run listed 143 fetches, 325.2 MiB download and
1015.5 MiB unpacked, with no builds. Fetch-only `nix copy --from
https://cache.nixos.org` succeeded for its output; cache-signature verification
also succeeded. Later metadata checks and dry runs covered all six unmodified
package/platform combinations. They do not reveal historical cache publication
times or guarantee that future closures remain cached. Neither supplied pin
provides Intel-Mac support here; Apple Silicon is the relevant Darwin target.

See the reusable procedure in
[Exact-output cache checks before expensive agent builds](../solutions/tooling-decisions/exact-output-cache-checks-before-agent-builds.md).

## Actual cached Nixpkgs Linux runtime

Executed output:

```text
/nix/store/v1wd180yd4pnz94fmphk4ijmnwmfngvx-codex-0.164.0
```

- CLI reported `codex-cli 0.164.0`; doctor reported consistent installation.
- Code-mode protocol/session handshake succeeded. JavaScript returned `9,64,4`,
  then a second cell returned `23` from persisted state. Helper exit status was 0.
- Voice helper reached `runtimeReady` and closed with exit status 0. This did not
  open devices, capture audio, or call a model.
- Manifest/resources, completions, Nix glibc interpreters and OpenSSL linkage were
  checked. Packaged ripgrep 15.2.0 and bubblewrap 0.12.0 executed. Full sandbox
  execution was not tested.
- The real TUI reached its idle composer without a daemon package, daemon PID or
  updater PID. Features showed `daemon_auto_start=false` and `code_mode_host=true`.
- Explicit daemon start/stop succeeded, but copied about 618 MiB into isolated
  HOME, materializing helper symlinks. The copy retained its Nix-store interpreter;
  it was not independently portable. A channel marker appeared even with updates
  disabled. Post-upgrade/GC behavior was not tested.

## Daemon and maintenance ownership differ

The pinned
[llm-agents recipe and patch](https://github.com/numtide/llm-agents.nix/tree/53a2d94ce3b88753200be9a0549d8978b031fa60/packages/codex)
build CLI/code-mode and construct the required package layout. For newly prepared
or explicitly selected installations, the patch selects the immutable store
package without copying or upstream replacement. Existing HOME/standalone daemon
installations are not automatically migrated and may remain selected; inspect
existing state before assuming daemon ownership changed. The October 2 patch also
attempts GC-root registration for the selected store package. Voice is not
packaged by this recipe.

The pinned
[Nixpkgs recipe](https://github.com/NixOS/nixpkgs/blob/17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09/pkgs/by-name/co/codex/package.nix)
builds CLI/code-mode and voice on supported targets, supplies runtime dependencies,
and includes targeted daemon/voice tests. It
[disabled automatic daemon startup on September 26](https://github.com/NixOS/nixpkgs/commit/dfd9ad2abfb21fc977f2fe636af8f0d18c0b0d60).
Explicit startup retains the HOME-copy behavior observed above. Voice dependencies
also make its closure larger. Both recipes skip the broad upstream test suite.

Nixpkgs is a simpler initial candidate when the daemon should remain off and the
desired version is in Toolnix's chosen, cache-complete Nixpkgs pin. llm-agents is a
better fit for a deliberate store-owned daemon policy, provided its own cached
input identity is preserved or rebuilding is explicitly accepted. Neither is an
automatic security or cache-availability guarantee.

## eMudhra TLS: useful evidence, incomplete proof

The 0.164.0 source locks `webpki-roots` 1.0.10 and `rustls-webpki` 0.103.16, and its
release notes include the dependency update. Native TLS remains the default;
custom CA configuration selects rustls. The executed Nixpkgs Linux binary links
OpenSSL 3.5.9. Fixed Rust dependencies alone do not prove every TLS path is fixed.

Against the [advisory](https://emudhra.we-have-a-problem.com/), unauthenticated
doctor probes sent HEAD `/responses` and GET `/models`, not authenticated inference:

| Probe | Observed result | Interpretation |
| --- | --- | --- |
| Healthy advisory origin | HTTP 404 on API paths | TLS/HTTP reached; not a model API |
| Direct G3B, AAA cross-chain, AAA No-CT incident hosts | `TLS handshake or certificate validation failed` | TLS-layer failure, not a certificate-specific rejection reason |
| Explicit incident-root bundle selecting rustls | Generic `connect failed` on incident hosts | Inconclusive |
| Healthy origin with the same custom bundle | HTTP 404 | Custom-bundle control reached HTTP |
| Independent curl, same bundle, AAA No-CT | HTTP 200; verification result 0 | Endpoint reachable and trusted by that control |

Earlier generic Codex connection errors remain inconclusive. Doctor's nonzero
status on a healthy origin reflected non-API routes, not a failed runtime launch.
The advisory provides 14 endpoint chains; this was not exhaustive coverage. No
universal eMudhra-remediation claim is warranted from these probes.

## Conditional future assessment, not a migration TODO

If a durable reminder is wanted, its wording should be conditional:

> Codex remains disabled with no re-enable date. Only if the owner explicitly
> requests re-enablement, reassess current Nixpkgs `pkgs.codex` versus
> upstream-pinned llm-agents. Do not automatically re-enable or switch packages.

Acceptance criteria for that future assessment:

1. Explicit owner approval for re-enablement and the required platform/features.
2. Exact locked Linux/Apple Silicon closures trusted and substitute-complete,
   including follows/override effects. Ask before a substantial source build.
3. Isolated CLI/code-mode/required-helper checks on actual target runtimes and
   meaningful healthy/revoked/No-CT TLS controls; generic failures are inconclusive.
4. Documented and tested daemon/updater plus upgrade/GC ownership, preserving
   Toolnix preferences and user credentials/history.

Open questions include Apple Silicon runtime execution, full sandbox/audio
functionality, all 14 TLS chains, and daemon/updater lifecycle across upgrades and
garbage collection. No future work is scheduled by this research record.
