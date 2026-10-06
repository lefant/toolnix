---
date: 2026-10-06
status: ✅ COMPLETED
---

# Matt Pocock v1.3.1-compatible pin

Both Toolnix locks now pin published `lefant/agent-skills` revision
`a2e354b3d10cdd406da2269074a210a4993466a4`. Its 27 published packages
match upstream tag `v1.3.1` (`24fe0ef7737efae15c87225755e9f6f5965e4888`)
except for one later sentence in `ask-matt/SKILL.md`: the tag recommends
`retro` after a difficult bug, while the vendor still mentions an architecture
handoff. The generated manifest discloses the difference. The canonical vendor
README still claims v1.2.3; a future canonical update should correct it. No
unpublished `agent-skills` commit is required to build Toolnix.

The packaged set includes `implement-spec`, `pr`, and `retro`, not
`resolving-merge-conflicts`. Toolnix has no `CONTEXT.md` or `CONTEXT-MAP.md` to
rename; consumers with existing domain documents must move them to
`GLOSSARY.md` and `GLOSSARY-MAP.md` before using the new skills. The native
Home Manager skill trees use the canonical vendor directories; Amp gets the
namespaced `mp` plugin via the guarded exporter, not a parallel vendoring layout.

Verification: targeted MP package and two checks passed. Full
`nix --accept-flake-config flake check --no-eval-cache -L` passed (16 checks).
The packaging test confirmed 27 skills, 82 files below Amp's 200-file limit,
16 manual flags, license and resource fidelity, local SKILL links and Skill-tool
targets, and exporter collision safety. A disposable Amp plugin load found
27 `mp:*` skills, including the three additions, and zero discovery errors.
No host activation or plugin publication occurred.

Upstream review: the added `implement-spec` instructs agents to make branches,
worktrees, merges and possibly draft PRs; these remain use-time operations and
do not override Toolnix approval rules. `retro` suggests environment changes
but asks the user to choose; `pr` carries its upstream `CREDITS.md` attribution.
Previously reviewed wizard, diagnostic capture, and CDN risks still apply.
