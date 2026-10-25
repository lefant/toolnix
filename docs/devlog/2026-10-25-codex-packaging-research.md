---
date: 2026-10-25
status: ✅ COMPLETED
related_research: docs/research/2026-10-25-codex-packaging-and-update-cadence.md
---

# Codex packaging research

## Outcome

Documented the read-only investigation of upstream archives, cached Nix packages,
Linux runtime behavior, eMudhra TLS evidence, and recent Codex update cadence in
[the research record](../research/2026-10-25-codex-packaging-and-update-cadence.md).
The owner's direction is to leave Codex disabled with no re-enable date; the
separate security/update work owns that implementation. This documentation does
not change the package selection or implement a rollout.

## Findings retained

- Both package repositories updated Codex frequently. The eight-week comparison
  favored llm-agents' lag; the latest four-week comparison favored Nixpkgs'.
- Both unmodified package configurations had cached outputs on Linux and Apple
  Silicon. Overriding llm-agents' Nixpkgs input reproduced the different, uncached
  output responsible for the source thread's expensive build.
- The cached Nixpkgs Linux CLI, code-mode/voice helpers, TUI and explicit daemon
  were exercised. Default daemon behavior and mutable-copy ownership differ from
  llm-agents' store-resident daemon policy.
- TLS-layer failures on incident hosts are stronger than generic connection
  failures, but do not establish universal certificate-specific remediation.
- A custom upstream-binary package or writable release-channel updater is not
  automatically a smaller maintenance burden than an existing cached Nix package.

## Reusable lesson

Captured one `ce:compound` learning:
[check exact output/cache identity before expensive agent builds](../solutions/tooling-decisions/exact-output-cache-checks-before-agent-builds.md).
It distinguishes recipe freshness, cache substitution, and runtime verification,
and uses guarded evaluation/dry runs before any substantial build.

## Verification and limits

Research evidence and dated primary sources are linked from the research record.
Documentation closeout checks cover frontmatter, relative links, claim grounding,
and whitespace; they do not repeat the runtime probes or build packages.
The grounding review corrected the daemon-policy scope: llm-agents does not
automatically migrate every existing HOME-owned daemon to its store package.
Frontmatter safety, seven relative links, Bash example syntax, and the staged
whitespace check passed. External dependency pins and Amp thread IDs were
confirmed as intentional mechanical-validator flags, not local Git commits.

The full compound pass found related but distinct cache/lockfile guidance, no
relevant local session files, and no qualifying project-specific vocabulary.
Existing agent instructions already surface the solutions directory; no glossary
or instruction changes were needed.

No source build, authenticated model call, package switch, or host activation was
performed by this research. Apple Silicon runtime, exhaustive TLS chains, and
post-upgrade/GC daemon behavior remain unverified. Future re-enablement requires
an explicit owner decision, not an unconditional migration TODO.
