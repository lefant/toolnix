---
date: 2026-10-07
status: ✅ COMPLETED
related_research: docs/research/2026-03-30-beads-dolt-adoption-for-hackbox-ctrl-and-toolnix.md
---

# Remove Beads from Toolnix

Removed Beads from the shared agent package list and removed
`BEADS_NO_DAEMON` from both the shared environment and wrapped Pi launcher.
Home Manager and devenv consume the same baseline, so both stop providing
Beads. Claude Code, Codex, OpenCode, Pi, Amp, their settings, and skill wiring
remain unchanged. No Beads-specific hooks, aliases, MCP servers, or other
active integrations were found in the tracked repository.

The earlier adoption research is marked superseded. Historical package-version
records, plans, and environment reviews remain intact. The shared `llm-agents`
input is still required for the other tools; its lockfiles were not changed.
No host was activated, and no user-owned Beads data was deleted.

## Verification

- `nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage .#toolnix-pi --no-link` passed.
- `devenv shell -- bash -c '…'` passed assertions that `bd` was absent,
  `BEADS_NO_DAEMON` was unset, and `claude`, `codex`, `opencode`, `pi`, and
  `amp` remained available.
- Inspected built outputs: no `bd` in the Home Manager profile, no Beads
  settings in generated session variables or the Pi launcher, and all five
  other agent executables present in the profile.
- `nix --accept-flake-config flake check --no-build --no-eval-cache` passed.
- `git diff --check` passed. A tracked-source search found Beads references
  only in historical documentation and this removal record.

No new test harness was added for this configuration deletion: actual Nix
builds, shell assertions, and generated-output inspection cover the affected
surfaces. Existing Nix trust/derivation-context warnings and a devenv CLI/input
version notice did not prevent verification.

Code review: skipped (ce-code-review unavailable). The harness restricts
delegating routine self-review; a direct diff review found no unrelated edits.
