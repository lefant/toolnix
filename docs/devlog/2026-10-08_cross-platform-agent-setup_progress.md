---
date: 2026-10-08
status: 🔄 PARTIAL
related_plan: docs/plans/2026-10-08-0930-feat-cross-platform-user-agents-plan.md
---

# Cross-platform agent setup progress

## Summary

The shared Home Manager agent module, scoped configuration adoption, and Apple Silicon browser packaging are implemented locally on `feat/cross-platform-user-agents`. Beads removal was already on origin/main and is included. Delivery is incomplete: native browser/session verification, final Mac integration and activation, account-plugin discovery, final code review, documentation, and pushes remain.

## Verified checkpoints

- Linux Home Manager activation package, wrapped Pi, agent-profile/adoption, browser-platform, browser-tools-packages, Compound opt-out, Matt Pocock baseline, and Antithesis baseline builds pass.
- Linux flake check without builds passed before the final platform-check correction; it explicitly omitted native Darwin evaluation.
- Adoption tests cover dry run, disabled/retargeted entries, repeat conflict, private backups, symlink ancestors, failed rename, and auth/history sentinels.
- Portable preferences derive from the existing templates, dropping Claude project-MCP policy, Codex project trust, and OpenCode blanket permission allowance. Full Linux profiles retain the original templates and runtime seed.
- The Mac thread reports native agent-profile/adoption and wrapped tmux builds passed on an earlier transferred checkpoint. Native full flake evaluation exposed unconditional Linux Chromium comparisons; those were fixed here and await the updated native check.

## Mac ownership and blocker

[Mac implementation thread](https://ampcode.com/threads/T-01a11b01-2af8-77b2-8fd5-161c32d07735) owns changes in the actual personal and company checkouts. Parent inspected its private migration patches. The personal host now consumes the standalone company module; old, new, and running host system derivations match exactly. Personal and company migration commits are local; company publication is excluded.

The Mac daemon does not yet trust Numtide, causing large source-build fallback. A cache-only host configuration built successfully and preserves trusted-users. Parent reviewed that narrow patch; a human administrator switch is required before continuing heavy native builds. No agent configuration has been activated.

## Resume

1. Confirm cache-only Mac activation with the user and verify cache trust in the runner thread.
2. Continue native checks from the latest transferred Toolnix snapshot, not the old snapshot or origin/main.
3. Verify browser modes with disposable state and inspect a screenshot; verify account/local Amp discovery without duplicate collections.
4. Complete Mac integration, settings/runtime ownership checks, documentation, full regression checks, and code review before final publication and agent activation.

Do not mistake transferred snapshots or Linux builds for proof of the final published Mac pin. Preserve existing Mac credentials and administrator checkpoints. Keep private migration patches and backups out of this repository.
