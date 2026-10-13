---
date: 2026-10-08
status: 🔄 PARTIAL
related_plan: docs/plans/2026-10-08-0930-feat-cross-platform-user-agents-plan.md
---

# Cross-platform agent setup progress

## Summary

The shared Home Manager agent module, scoped configuration adoption, and Apple Silicon browser packaging are published on `feat/cross-platform-user-agents`. The user activated the verified personal Mac configuration in generation 17. Linux preservation, native builds, and installed browser checks pass. Remaining human steps are the app-managed runner restart and agent sign-ins; authenticated model requests are not verified. Neither feature branch is merged, and company changes remain local. Earlier checkpoints below describe the implementation sequence, not current blockers.

## Verified checkpoints

- Linux Home Manager activation package, wrapped Pi, agent-profile/adoption, browser-platform, browser-tools-packages, Compound opt-out, Matt Pocock baseline, and Antithesis baseline builds pass.
- Linux flake check without builds passed before the final platform-check correction; it explicitly omitted native Darwin evaluation.
- Adoption tests cover dry run, disabled/retargeted entries, repeat conflict, private backups, symlink ancestors, failed rename, and auth/history sentinels.
- Portable preferences derive from the existing templates, dropping Claude project-MCP policy, Codex project trust, and OpenCode blanket permission allowance. Full Linux profiles retain the original templates and runtime seed.
- The Mac thread reports native agent-profile/adoption and wrapped tmux builds passed on an earlier transferred checkpoint. Native full flake evaluation exposed unconditional Linux Chromium comparisons; those were fixed here and await the updated native check.

## Initial Mac ownership and cache blocker

[Mac implementation thread](https://ampcode.com/threads/T-01a11b01-2af8-77b2-8fd5-161c32d07735) owns changes in the actual personal and company checkouts. Parent inspected its private migration patches. The personal host now consumes the standalone company module; old, new, and running host system derivations match exactly. Personal and company migration commits are local; company publication is excluded.

The Mac daemon does not yet trust Numtide, causing large source-build fallback. A cache-only host configuration built successfully and preserves trusted-users. Parent reviewed that narrow patch; a human administrator switch is required before continuing heavy native builds. No agent configuration has been activated.

## Resume

1. Have the user pause other active Mac runner threads and toggle Amp.app's runner off/on.
2. Rerun the personal repository's `scripts/check-coding-agents.sh` in that actual runner; a fresh login shell already passes, but the existing runner still resolves the native Amp first.
3. Complete human-controlled Claude and Pi sign-ins; verify OpenCode provider access without exposing credentials. Do not report stored-login status as a successful model request.

Do not mistake transferred snapshots or Linux builds for proof of the final published Mac pin. Preserve existing Mac credentials and administrator checkpoints. Keep private migration patches and backups out of this repository.

## Post-cache verification

The user activated the cache-only host (generation 16). Native builds now use the
cache. Darwin flake evaluation, agent-profile/adoption, browser-platform, wrapped
Pi, and wrapped tmux pass. Both native Darwin and Linux disposable browser proofs
passed same-run retention, fresh state loss, explicit named restore, concurrent
isolation, and an untouched disposable everyday sentinel. Screenshots were inspected;
no personal browser data was accessed. The script closes sessions as it proceeds
to keep at most three live browsers.

Linux `devenv shell -- true`, the focused nine-build set, and flake evaluation
pass. `scripts/check-agent-profile.py` compares source-captured configuration
contents, package identities, environment, targets, and force flags against the
pre-extraction merge base: equal after repository-source/statusline path
normalization. Negative controls reject model, trust-path, CLI, and skill removal.

Portable Codex now supplies three Nix preferences through leading CLI overrides,
leaving its writable trust/configuration file unmanaged. Explicit later overrides
remain available; profiles cannot override those invocation preferences. Claude
and Pi retain immutable preference files, so in-app saves may fail or be session-only.
This preserves the existing full Linux profile while avoiding Codex trust-write failures.

Signed-in Mac Amp discovery confirmed 51 account User Skills plus CE/MP/Antithesis
plugins. The portable profile keeps the remaining 25 skill names locally and moves
Codex's full baseline to its own tree to avoid shared Amp duplication. Account
revisions are not asserted equal to the Nix-pinned source.

All five CLI versions execute and match across native Mac and Linux: Claude
2.1.285, Codex 0.159.2, Pi 0.99.1, Amp 0.0.1790712063-gb89205, OpenCode 1.18.33.
The native development host with user-only Home Manager builds. Its Home Manager
library uses the Toolnix-compatible extended library without changing system pins.
Final published-pin build, agent activation, and actual runner restart verification
remain outstanding; the older native Amp currently shadows the pending user profile.

Code review: skipped (ce-code-review unavailable) — the skill was invoked, but
this harness disallows routine self-review delegation. Direct diff review covered
module ownership, Linux preservation, portable trust policy, backup failure paths,
wrapper precedence, platform selection, and account/local discovery. A focused
Oracle consultation resolved the Codex runtime-state boundary; it was not a general
review receipt. No PR or merge is authorized. Repository workflow inspection found
no GitHub Actions workflows for Toolnix; publication is a feature-branch checkpoint.

## Published-pin activation

The user activated personal [57f7345](https://github.com/lefant/nix-darwin/commit/57f7345adeb0ed2480407829bee7e294634404eb),
which locks [Toolnix c5e53ea](https://github.com/lefant/toolnix/commit/c5e53ea63151a50441e92df2104143989d73415b).
The native runner verified generation 17 at the previously built
`/nix/store/q6lng8cdq2qa91qrsaj4vm6hnffp2509-darwin-system-26.05.c3e90c8`.
Home Manager installed the user packages and links successfully. Codex's runtime
config remains a writable, user-owned regular file. The installed user-profile
browser passed the disposable session tests.

The login-shell verifier exits 0. The existing runner verifier exits 1 because
`~/.local/bin/amp` still precedes the Nix profile in its inherited PATH; the other
four agents already resolve through the Nix profile. The user-owned shell PATH
adjustment is in place, but no runner was restarted automatically.

Safe status checks report Codex and Amp signed in, Claude not signed in, and Pi's
configured provider not ready. OpenCode has no stored credentials and detects
provider environment variables; their presence does not establish working API
access. No sign-in state was changed, and no authenticated model request is claimed.
