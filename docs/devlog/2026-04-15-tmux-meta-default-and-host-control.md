---
date: 2026-04-15
status: ✅ COMPLETED
related_plan:
related_issues: []
---

# Implementation Log - 2026-04-15

**Implementation**: Made `tmux-meta` available by default, kept inventory/control-host wrappers gated behind `toolnix.enableHostControl`, and re-applied the updated host config on `lefant-ctrl`.

## Summary

A recent `toolnix` rollout on `lefant-ctrl` removed `tmux-meta` because the function lived behind the opt-in host-control gate. This session split that boundary more cleanly: `tmux-meta` now ships by default because it only depends on a secondary tmux socket and config, while inventory-specific helpers such as `target-entry` and `targets` remain gated behind `toolnix.enableHostControl`. The Home Manager host profile, option description, and maintainer-facing docs were updated accordingly. The updated config was then applied on `lefant-ctrl`, and the host-specific bootstrap flake there was re-rendered against the local checkout with `toolnix.enableHostControl = true;` so `target-entry` and `targets` were restored as well.

## Plan vs Reality

**What was planned:**
- [x] Confirm whether `lefant-ctrl` had recently been switched to a newer `toolnix` generation
- [x] Restore `tmux-meta` on `lefant-ctrl`
- [x] Identify the other host-control-gated features
- [x] Make `tmux-meta` available by default because it is low-risk and inventory-free
- [x] Re-enable host-control wrappers specifically on `lefant-ctrl`

**What was actually implemented:**
- [x] Confirmed `lefant-ctrl` was on Home Manager generation `id 12` from 2026-04-15
- [x] Split `modules/shared/host-control.nix` into inventory-gated shell helpers and always-on `tmux-meta`
- [x] Updated `internal/profiles/home-manager/core.nix` so `.tmux.conf.meta` is always managed and `tmux-meta` is always injected
- [x] Narrowed the `toolnix.enableHostControl` option description to cover only `target-entry` and `targets`
- [x] Updated `README.md`, `docs/reference/architecture.md`, and `docs/reference/maintaining-toolnix.md`
- [x] Rebuilt and activated the host config on `lefant-ctrl`
- [x] Re-rendered the local bootstrap flake on `lefant-ctrl` against `path:/home/exedev/git/lefant/toolnix` with `toolnix.enableHostControl = true;`

## Challenges & Solutions

**Challenges encountered:**
- The first build after refactoring `modules/shared/host-control.nix` failed because the new attrset fields referenced each other without recursive scope.
- `lefant-ctrl` is not driven by a tracked `homeConfigurations.<host>` output in the repo, so the host-specific gate also had to be reflected in the local bootstrap flake used on the VM.

**Solutions found:**
- Changed the host-control attrset to `rec` so `zshBody` could reference the newly split fields.
- Re-applied the host state on `lefant-ctrl` with `scripts/bootstrap-home-manager-host.sh --toolnix-ref path:/home/exedev/git/lefant/toolnix --enable-host-control` so the active machine-local bootstrap recipe matches the desired host-specific gate.

## Learnings

- `tmux-meta` is operationally separate from inventory access and fits better as a default host capability than as a control-host-only wrapper.
- The real inventory/control-host gate in practice is very small: `HACKBOX_CTRL_INVENTORY_ROOT`, `target-entry`, and `targets`.
- On self-hosted machines that use the standalone bootstrap flake path, host-specific toggles such as `toolnix.enableHostControl` live in the machine-local rendered bootstrap recipe rather than in the published flake alone.

## Next Steps

- [ ] Push and later consume the published `toolnix` revision on any other hosts that should inherit the new default `tmux-meta` behaviour.
- [ ] Decide whether `lefant-ctrl` should keep following the local `path:` bootstrap ref during active development or return to `github:lefant/toolnix` after this change lands.
