---
date: 2026-10-02
status: ✅ COMPLETED
related_issues:
  - https://github.com/lefant/agent-skills/pull/5
---

# Prepare the Matt Pocock Amp plugin

Implemented and verified locally; publication remains deliberately unperformed.
Both Toolnix lockfiles now consume the merged
[agent-skills source](https://github.com/lefant/agent-skills/commit/9b6fb9b7e083fda0e31614f011cf38f995e5d844).
The `matt-pocock-amp-plugin` package and
`scripts/export-matt-pocock-amp-plugin.sh` prepare a directory plugin named `mp`.
All 27 upstream v1.2.3 packages are registered, with 82 output files: the 79
package files, MIT license, entrypoint, and provenance manifest.

## Decisions and review

- Inspected CE's renderer/exporter history and its
  [implementation thread](https://ampcode.com/threads/T-01a08687-ee7a-705a-b2b9-80b3b44a37d1).
  Reused literal registration and guarded local export conventions. Kept the
  MP renderer separate: CE strips prefixes and consolidates references; MP
  preserves every resource path and does not need consolidation.
- Each `SKILL.md` preserves upstream frontmatter and body, with an added mapping
  of all internal skill calls to `mp:*`. This is instruction-level routing,
  not a runtime alias; global replacement would corrupt generic words such as
  `research` and `prototype` in metadata, paths, and ticket types.
- Filtered MP before name deduplication in both Amp-discovered Home Manager
  trees. Claude, OpenCode, and Pi retain MP; Codex receives an explicit MP tree.
  Home Manager does not install the Amp plugin automatically.
- Self-reviewed packaging, discovery paths, export replacement guards, and
  source fidelity. No independent agent/model review was run.
- Read both Bash templates and report CDN references. The wizard example can
  write real credentials to `.env` and GitHub Actions; the diagnostic template
  echoes captured observations. Report HTML loads remote Tailwind and Mermaid
  scripts. These are documented use-time concerns, not installation actions.

## Verification

- `nix --accept-flake-config flake check --no-eval-cache -L`: passed, including
  existing CE checks and both new MP checks. Normal Nix warnings about unchecked
  custom outputs and cache trust remain; no host activation was performed.
- MP export check: **27 skills, 82 files, 16 manual flags**, exact supporting
  resource/license fidelity, preserved upstream frontmatter/body, repeat export,
  stale-file removal, collision rejection, and invalid-source nonreplacement.
  An initial test-fixture failure copying read-only Nix directories was fixed
  by making the disposable fixture writable before mutation.
- Baseline check: no bare MP in either Amp tree; all 27 MP packages in each
  explicit Claude, OpenCode, Pi, and Codex tree.
- `devenv shell -- shellcheck scripts/export-matt-pocock-amp-plugin.sh`: passed.
  `bash -n` passed for the exporter and both unchanged upstream Bash templates.
- Local exporter build path, plugin load, `amp skills list --json`,
  `amp skill info mp:tdd --json`, and resource reads succeeded: **27 MP and 33 CE
  skills, zero discovery errors**. The temporary `.amp/plugins/mp` copy was
  removed after the loading proof; generated snapshots are not tracked here.
- An explicit `--override-input agent-skills path:... --no-write-lock-file`
  package build also passed; its manifest correctly records `unlocked` rather
  than claiming a published vendor revision.

## Amp manual-only limitation

Amp `0.0.1790926488-g24b332` exposed manual-flagged skill descriptions and allowed
the model-facing skill tool to load `mp:grill-me` in a read-only verification.
Preserving `disable-model-invocation: true` therefore does not enforce manual-only
use on this version. Added manual-use guidance requires an explicit user request
for the skill; this remains a prompt rule, not a permission boundary. No interview,
project setup, tracker operation, credential operation, or report rendering ran.

The durable usage and publication instructions are in
[maintaining-toolnix](../reference/maintaining-toolnix.md#prepare-matt-pococks-mp-plugin-alongside-ce).
Select MP or CE explicitly per task, and compare them in fresh threads.

## Delivery boundary

Local implementation only. Toolnix has not been pushed and the MP plugin has not
been published to Personal/User or Workspace Plugins. A later approved export,
review, and push to the user's Plugins repository is required for availability
across Amp projects and orbs. Toolnix shipping requires its own authorization.
