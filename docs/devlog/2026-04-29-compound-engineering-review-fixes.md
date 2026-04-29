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
- Split Home Manager gating into target-level agent toggles and skill-specific target toggles:
  - target agents/extensions still follow `toolnix.compoundEngineering.<target>.enable`
  - target skill trees also require `toolnix.compoundEngineering.skills.enable`

## Validation

Commands run:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
nix flake check --no-build
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
- `codex debug prompt-input` still discovers Compound skills from `compound-engineering-codex-assets`.
- `codex debug prompt-input` does not show duplicate Compound skills from `compound-engineering-pi-assets` or the Claude-only `ce-update` skill.
