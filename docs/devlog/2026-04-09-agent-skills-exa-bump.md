---
date: 2026-04-09
status: ✅ COMPLETED
related_issues: []
---

# Implementation Log - 2026-04-09

**Implementation**: Bumped the pinned `agent-skills` input so `toolnix` picks up the new custom `exa` skill

## Summary

Updated `toolnix` to the latest `github:lefant/agent-skills` revision after landing a new custom `exa` skill in the upstream skills repository. The only required repo changes here were lockfile refreshes because `modules/shared/agent-baseline.nix` already builds the managed skill tree automatically from the `lefant/` and `vendor/` directories of the pinned `agent-skills` input. This means the new `exa` skill becomes available to `toolnix` consumers without any additional module wiring once the input revision is refreshed.

## Plan vs Reality

**What was planned:**
- [ ] Update the pinned `agent-skills` revision after the Exa skill lands upstream
- [ ] Keep the `toolnix` change narrowly scoped to the input refresh
- [ ] Record the update in a repo devlog

**What was actually implemented:**
- [x] Refreshed `flake.lock` for input `agent-skills`
- [x] Updated the matching `agent-skills` entry in `devenv.lock`
- [x] Confirmed the new pinned revision is `592e577493bae61f17c30fa972a30224826fe818`
- [x] Kept `toolnix` source modules unchanged because the managed skill tree already auto-discovers custom skills from the input
- [x] Wrote this devlog entry

## Challenges & Solutions

**Challenges encountered:**
- `toolnix` maintains both `flake.lock` and `devenv.lock`, so the `agent-skills` bump needed to stay aligned across both files.

**Solutions found:**
- Used `nix flake lock --update-input agent-skills` to refresh `flake.lock`, then mirrored the same resolved `agent-skills` revision, timestamp, and nar hash into `devenv.lock`.

## Learnings

- `toolnix`'s current `agent-baseline` design is doing the right thing here: adding a new custom skill upstream does not require any local code changes beyond moving the pinned input forward.
- Keeping the lockfile bump isolated makes this kind of shared-skill rollout cheap and reviewable.

## Next Steps

- [ ] Pull the updated `toolnix` revision anywhere the wrapped `pi` or Home Manager-managed skill tree is consumed and verify the `exa` skill appears in the managed skill set
