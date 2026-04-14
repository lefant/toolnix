---
date: 2026-04-12
status: ✅ COMPLETED
related_issues: []
---

# Implementation Log - 2026-04-12

**Implementation**: Added a toolnix-managed shared context file that enables Caveman lite mode by default for Claude, Codex, and Pi

## Summary

Added a tracked shared agent context file under `agents/shared/templates/caveman-lite-context.md` and wired it into the declarative Home Manager-owned runtime state for the main coding agents managed by `toolnix`. The Home Manager profile now installs this file as:

- `~/.claude/CLAUDE.md`
- `~/.codex/AGENTS.md`
- `~/.pi/agent/AGENTS.md`

This makes Caveman lite the default conversational style for those agents without requiring per-session manual activation. The wrapped `toolnix-pi` path was also updated so its dedicated wrapped agent directory gets the same `AGENTS.md`, keeping wrapped and non-wrapped Pi behavior aligned.

## Plan vs Reality

**What was planned:**
- [ ] Enable Caveman lite by default through tracked `toolnix` agent configuration
- [ ] Avoid relying on ad hoc machine-local files outside the repo
- [ ] Keep wrapped `toolnix-pi` behavior aligned with Home Manager-managed `~/.pi/agent/`
- [ ] Record the change in a repo devlog

**What was actually implemented:**
- [x] Added `agents/shared/templates/caveman-lite-context.md`
- [x] Wired `~/.claude/CLAUDE.md` to the tracked shared context file
- [x] Wired `~/.codex/AGENTS.md` to the tracked shared context file
- [x] Wired `~/.pi/agent/AGENTS.md` to the tracked shared context file
- [x] Updated `flake-parts/wrapped-tools.nix` so wrapped `toolnix-pi` links the same `AGENTS.md` into its isolated runtime state
- [x] Wrote this devlog entry

## Challenges & Solutions

**Challenges encountered:**
- The existing machine had non-toolnix symlinks for Claude and Codex context files, so enabling this through `toolnix` required taking declarative ownership of those files.
- Wrapped `toolnix-pi` uses a separate runtime directory via `PI_CODING_AGENT_DIR`, so updating only `~/.pi/agent/AGENTS.md` would not have covered the wrapped path.

**Solutions found:**
- Managed the context files directly through Home Manager with `force = true`, so the tracked toolnix defaults become authoritative.
- Added the same shared context file to the wrapped Pi bootstrap path in `flake-parts/wrapped-tools.nix`.

## Learnings

- A small shared context file is the simplest cross-agent path for default style behavior; it is more predictable than hoping each agent auto-invokes the Caveman skill.
- Wrapped-tool paths need explicit parity work whenever a new managed agent-side file is introduced.
- Keeping the instructions at the `lite` level is a good fit for always-on defaults because it reduces verbosity without making safety or operational output too telegraphic.

## Next Steps

- [ ] Run `home-manager switch --flake .#lefant-toolnix` on hosts that should receive the new defaults
- [ ] Consider whether the same shared context file should also be wired into other managed agents such as OpenCode or Amp
