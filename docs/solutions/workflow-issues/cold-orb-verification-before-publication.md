---
title: Verify reconstructed Toolnix trees in a cold orb before publication
date: 2026-10-25
category: workflow-issues
module: Toolnix local readiness verification
problem_type: workflow_issue
component: development_workflow
severity: medium
applies_when:
  - "Verifying an unpublished Toolnix implementation independently of a warm development environment"
  - "Reconstructing behavior when the original checkout and its test evidence are unavailable"
  - "Preparing publication evidence without authorizing host activation"
tags: [readiness, verification, cold-orb, source-provenance, nix, home-manager]
---

# Verify reconstructed Toolnix trees in a cold orb before publication

## Context

The [2026-10-25 recovery](../../research/2026-10-25-trust-update-recovery.md)
reconstructed intended behavior from an inaccessible thread's export. It did
not recover the exact lost tree. Historical success reports therefore could not
certify the reconstruction, and a warm development store could hide dependencies
that a fresh consumer would need to obtain.

The [verification devlog](../../devlog/2026-10-25-trust-update-recovery.md)
records a cold-orb repeat against the supplied candidate before publication.
This learning describes that verified workflow, not another runtime test run.

## Guidance

1. **Identify the candidate before transferring it.** Record the full base
   commit, both lockfiles, and the exact changes, including new files and binary
   content. A binary-capable patch alone does not include untracked files.
   Include a path/checksum manifest and hash the transfer archive. Verify patch
   applicability and resulting file hashes in a disposable checkout of that
   base. A branch name or narrative does not transfer unpublished work.
2. **Measure the cold starting point.** Use a separate orb without the project's
   warm snapshot or automatic setup.
   Record the platform, Nix version, store size/path count, existing outputs,
   and available tools before realization. A fresh orb is not an empty machine.
3. **Screen builds before running them.** Follow the existing
   [exact-output/cache procedure](../tooling-decisions/exact-output-cache-checks-before-agent-builds.md).
   Disable lockfile writes and unknown import-from-derivation builds during
   inspection. If evaluation needs a generator, inspect that exact derivation
   and its dependencies separately before realizing it. The recovery's two
   reviewed JSON-formatting generators did not justify unrestricted evaluation
   builds. Any large source build or retry still needs explicit owner approval.
4. **Exercise the intended consumers.** After reviewing dry runs, build the
   check derivations and Home Manager/Pi outputs without activating the profile.
   Run the produced Pi and a real clean devenv shell. Use an isolated HOME and
   controlled PATH/environment; inspect the closure and executable discovery.
   For a disabled integration, test existing true opt-ins and combined flags,
   not just the default configuration. Retained user configuration and absent
   executables are separate requirements.
5. **Keep security evidence specific.** Probe the rebuilt agent itself, through
   each relevant TLS API, with incident endpoints and healthy controls before
   and after them. Distinguish certificate errors from DNS and timeout failures.
   Test explicitly selected CA bundles separately from ordinary shell behavior.
   See the [runtime TLS learning](../tooling-decisions/pi-prebuilt-runtime-tls-verification.md)
   for artifact and probe selection; a matching version string is not enough.
6. **Compare the delivered code with the tested candidate.** Recheck the source
   manifest after testing. Preserve reproduction scripts, raw results, commands,
   exit statuses, and exact output paths in a checksummed evidence archive.
   Inspect returned changes before publication. Disclose later documentation-only
   edits; rerun affected checks if implementation or locks change. Keep private
   runtime state and credentials out of both the handoff and public Git history.
7. **Report evidence and permission separately.** Distinguish recovered reports,
   newly executed checks, and untested scope. Publication does not authorize
   activation, re-enablement, or future expensive builds. The
   [current trust-update policy](../../reference/maintaining-toolnix.md#current-trust-update-policy)
   owns the Codex/browser pause; older opt-in examples do not override it.

## Why This Matters

Source identity ties the results to one candidate. Cold-state measurements expose
reliance on local outputs but do not guarantee future cache availability. Runtime
checks establish more than evaluation or a successful build; positive controls
show that rejection is not merely broken networking. None of those observations
proves another platform or grants permission to deploy.

## When to Apply

- Before publishing a reconstructed or unpublished implementation.
- When earlier evidence came from a lost checkout or warm environment.
- When removing runtime tools must preserve configuration and user state.
- When a Linux result could be mistaken for Darwin or deployed-host readiness.

## Examples

The dated repeat applied the candidate to
[base f70bbc1](https://github.com/lefant/toolnix/commit/f70bbc18d6c2bab8e0a56c2c1fff8e13423274e1).
The initial store contained **67 paths / 113 MiB**, with no devenv or Toolnix
outputs. The devlog records input/evidence archive hashes and confirms that the
implementation and both locks stayed unchanged; only the devlog was extended
after verification. With explicit owner authorization, the recovery was published in
[62d7d8d](https://github.com/lefant/toolnix/commit/62d7d8deb842be19464234cfa63bf441e656dba6).

| Recorded result | What it establishes |
| --- | --- |
| All 13 Linux checks, Home Manager build, Pi discovery, and clean devenv smoke passed. | These Linux consumption paths worked without activation; authenticated inference was not tested. |
| Pi's embedded Bun 1.4.4 rejected 14/14 incident endpoints through each of `fetch` and `node:https`; four healthy requests per API returned HTTP 200. | Those embedded APIs rejected the tested chains, not every agent or trust mode. |
| The explicitly selected NSS 3.131.1 bundle rejected 14/14 endpoints and passed four controls. | That bundle worked when selected; ordinary curl still used OpenSSL default paths, with neither CA environment variable exported. |
| Disabled-runtime and combined-opt-in checks passed. | The tested Toolnix outputs omitted the disabled executables; other installations and running processes were not removed. |

Darwin Pi and portable browser-disable derivations were evaluated only: no native
build, runtime/TLS, runner PATH, adoption, or activation was verified.
No large source compilation occurred.
The rollout hold and separate approval requirements remained in place.

## Related

- [Readiness evidence and consumption-mode boundaries](../architecture-patterns/agent-native-readiness-specs-2026-05-04.md).
- [Disk-pressure triage](local-readiness-verification-disk-pressure-2026-05-06.md)
  separates capacity failures from product failures; do not treat a harness or
  environment repair as a product fix.
