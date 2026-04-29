# Compound Engineering Review Fixes

**Date:** 2026-04-29
**Status:** ✅ COMPLETED

## Summary

Ran a read-only Compound Engineering code review over the multi-target Compound fanout changes and fixed the actionable findings before leaving the default deploy path in place.

## Findings fixed

- OpenCode renderer ignored upstream `ce_platforms` and installed Claude-only skills such as `ce-update`.
- Codex renderer emitted TOML strings with Python `json.dumps` default `ensure_ascii=True`, producing surrogate-pair escapes for non-BMP characters that TOML rejects.
- Target-specific skill trees were gated only by target enable flags, so `toolnix.compoundEngineering.skills.enable = false` did not suppress Claude/OpenCode/Codex Compound skills.

## Implementation

- Added `ce_platforms` parsing/filtering to `render-opencode-assets.py`.
- Added the same platform filter to the Nix-side OpenCode skill link list so Home Manager does not link filtered-out skill paths.
- Changed Codex agent TOML string rendering to `json.dumps(..., ensure_ascii=False)`.
- Added a Nix build-time validation step that parses every generated Codex agent TOML file with Python `tomllib`.
- Fixed that build-time TOML validation to use the derivation output path through `OUT` and fail when no TOML files are rendered.
- Added flake checks for Compound asset rendering and the `toolnix.compoundEngineering.skills.enable = false` option matrix.
- Split Home Manager gating into target-level agent toggles and skill-specific target toggles:
  - target agents/extensions still follow `toolnix.compoundEngineering.<target>.enable`
  - target skill trees also require `toolnix.compoundEngineering.skills.enable`

## Document review follow-up

Ran a document review on `docs/plans/2026-04-29-compound-engineering-toolnix-integration.md` after the target fanout and review fixes landed. The review found the plan had become stale: it still described a Pi-only rollout, omitted OpenCode/Claude/Codex options, and did not record the new opt-out and asset-validation checks.

Updated the plan to reflect the current completed scope:

- Pi-first rollout followed by OpenCode, Claude Code, and Codex CLI fanout.
- Current Home Manager option matrix.
- Target-specific Home Manager links and renderers.
- `ce_platforms` filtering and Codex TOML validation.
- Opt-out matrix and no-installer validation.
- Remaining daily-use/model-backed follow-ups.

## Validation

Commands run:

```bash
nix flake check --no-build
nix build \
  .#checks.x86_64-linux.compound-engineering-assets \
  .#checks.x86_64-linux.compound-engineering-skills-opt-out \
  .#homeConfigurations.lefant-toolnix.activationPackage
./result-2/activate
codex debug prompt-input 'check compound assets'
```

Post-activation checks:

```bash
test ! -e ~/.config/opencode/skills/ce-update
python3 - <<'PY'
import tomllib
from pathlib import Path
for p in (Path.home() / '.codex/agents/compound-engineering').glob('*.toml'):
    tomllib.loads(p.read_text(encoding='utf-8'))
print('ok')
PY
```

Observed:

- `~/.config/opencode/skills/ce-update` is absent.
- All 51 generated Codex agent TOML files parse successfully.
- `nix flake check --no-build` evaluates the new Compound Engineering checks.
- `.#checks.x86_64-linux.compound-engineering-assets` verifies OpenCode/Codex platform filtering and parses all Codex agent TOML.
- `.#checks.x86_64-linux.compound-engineering-skills-opt-out` verifies `toolnix.compoundEngineering.skills.enable = false` removes Compound skills while preserving target-specific agent assets.
- `codex debug prompt-input` still discovers Compound skills from `compound-engineering-codex-assets`.
- `codex debug prompt-input` does not show duplicate Compound skills from `compound-engineering-pi-assets` or the Claude-only `ce-update` skill.
