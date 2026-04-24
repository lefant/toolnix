---
date: 2026-04-24
status: ✅ COMPLETED
related_issues: []
---

# Implementation Log - 2026-04-24

**Implementation**: Made the tracked `pi` default settings in `toolnix` compact much earlier by adding explicit aggressive compaction settings to the repo-managed template.

## Summary

This session updated the tracked `pi` settings template so `toolnix` now enables aggressive auto-compaction by default for the wrapped and Home Manager-managed Pi paths. The template already pinned `openai-codex/gpt-5.4` with `high` thinking, but it relied on Pi's default compaction thresholds. The new template adds an explicit `compaction` block with `reserveTokens = 100000` and `keepRecentTokens = 20000`, which causes compaction to trigger materially earlier while still keeping a sizeable recent working set verbatim.

## Plan vs Reality

**What was planned:**
- [ ] Find the repo-managed Pi settings source in `toolnix`
- [ ] Add explicit aggressive compaction defaults
- [ ] Record the change in a devlog
- [ ] Commit and push the update

**What was actually implemented:**
- [x] Confirmed `agents/pi-coding-agent/templates/settings.json` is the tracked Pi settings template used by `toolnix`
- [x] Added a `compaction` block with `enabled`, `reserveTokens`, and `keepRecentTokens`
- [x] Kept the existing default provider, model, and thinking level unchanged
- [x] Wrote this devlog entry

## What changed

Changed:

- `agents/pi-coding-agent/templates/settings.json`
- `docs/devlog/2026-04-24-pi-aggressive-compaction-defaults.md`

The Pi template now includes:

- `compaction.enabled = true`
- `compaction.reserveTokens = 100000`
- `compaction.keepRecentTokens = 20000`

Because both the Home Manager profile and the wrapped `toolnix-pi` path source the same tracked template, the new defaults apply consistently across both consumption modes.

## Verification

Verified the tracked settings file contains valid JSON with the new compaction block:

```bash
jq . agents/pi-coding-agent/templates/settings.json
```

Verified the repo wiring still points both default Pi consumption paths at the tracked template:

```bash
rg -n "pi-coding-agent/templates/settings.json" flake-parts/wrapped-tools.nix internal/profiles/home-manager/core.nix
```

## Challenges & Solutions

**Challenges encountered:**
- The work was initially started from the wrong repository, so the first step was to relocate the change into the actual `toolnix` source of truth.

**Solutions found:**
- Confirmed the tracked template path in `toolnix` before editing so the change lands in the repo-managed file that both wrapped and Home Manager-managed Pi setups consume.

## Learnings

- `toolnix` centralizes Pi defaults in `agents/pi-coding-agent/templates/settings.json`, and that single file is reused by both the wrapped `toolnix-pi` runtime and the Home Manager-managed `~/.pi/agent/settings.json` path.
- Making compaction behavior explicit in the tracked template is better than relying on Pi upstream defaults when the repo wants a stronger opinion about early context shedding.
- `keepRecentTokens = 20000` is a good companion to aggressive `reserveTokens` because it preserves a substantial recent verbatim tail while still forcing compaction to happen early.

## Next Steps

- [ ] Consider whether other tracked agent templates should align more explicitly on context-management defaults where long-running sessions are common
- [ ] If maintainers want the rationale surfaced in reference docs, add a short note to the Pi-related docs about why `toolnix` prefers aggressive compaction
