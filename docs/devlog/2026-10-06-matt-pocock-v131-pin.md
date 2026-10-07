---
date: 2026-10-06
status: ✅ COMPLETED
---

# Matt Pocock v1.3.1-compatible pin

Both Toolnix locks now pin published `lefant/agent-skills` revision
`ddc10f079e33701a6922a7ce0d97ef4978b23427`. Its 27 published packages
match upstream tag `v1.3.1` (`24fe0ef7737efae15c87225755e9f6f5965e4888`)
except for two harness-neutral Skill-tool calls in `implement/SKILL.md` in place
of `/tdd` and `/code-review`. The generated manifest discloses this intentional
difference; the canonical vendor README now records v1.3.1 provenance.

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
