# Compound Engineering OpenCode Default Integration

**Date:** 2026-04-29
**Status:** ✅ COMPLETED

## Summary

Added best-effort default OpenCode support for the Toolnix Compound Engineering integration. This follows upstream guidance that OpenCode uses the Compound converter target (`bunx @every-env/compound-plugin install compound-engineering --to opencode`) while keeping Toolnix declarative and offline at Home Manager activation time.

## Implementation

- Added `modules/shared/compound-engineering/render-opencode-assets.py` to render OpenCode-compatible assets from the pinned upstream plugin.
- Rendered Compound skills with OpenCode-oriented rewrites:
  - `.claude/` paths become `.opencode/` / `~/.config/opencode/` paths.
  - fully qualified Compound agent references are flattened to OpenCode agent filenames.
- Rendered Compound agents as OpenCode subagent Markdown files with `description` and `mode: subagent` frontmatter.
- Added `toolnix.compoundEngineering.opencode.enable`, defaulting to `true` when Compound Engineering is enabled.
- Updated Home Manager fanout:
  - `~/.config/opencode/skills` now uses an OpenCode-specific managed skill tree.
  - `~/.config/opencode/agents` now links the rendered Compound OpenCode agents.

## Validation

Commands run:

```bash
nix flake check --no-build
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
opencode agent list
```

Observed:

- `~/.config/opencode/skills` points to `toolnix-managed-opencode-skills-with-compound-engineering`.
- `~/.config/opencode/agents` points to `toolnix-compound-engineering-opencode-agents`.
- `opencode agent list` lists Compound agents such as `ce-code-simplicity-reviewer`, `ce-security-reviewer`, and other `ce-*` subagents.
- First validation caught that quoted `temperature` frontmatter is invalid for OpenCode. Removed generated temperature metadata and revalidated successfully.

## Caveats

- This avoids the upstream `bunx` installer during activation.
- The renderer ports the relevant upstream OpenCode conversion behavior instead of running the TypeScript converter.
- Model-backed OpenCode CE workflow validation remains a follow-up.
