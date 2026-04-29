# Compound Engineering Codex CLI Default Integration

**Date:** 2026-04-29
**Status:** ✅ COMPLETED

## Summary

Added best-effort default Codex CLI support for the Toolnix Compound Engineering integration. This follows upstream Codex guidance, which currently combines native Codex plugin installation for skills with the Compound Bun converter for agents, but implements the result declaratively from pinned Nix-store sources instead of invoking marketplace/TUI or `bunx` installers during activation.

## Implementation

- Added `modules/shared/compound-engineering/render-codex-assets.py` to render Codex-compatible assets from the pinned upstream plugin.
- Rendered Codex skills under `~/.codex/skills/compound-engineering`.
  - Skips Claude-only skills such as `ce-update` through `ce_platforms` filtering.
  - Rewrites `.claude/` paths to `.codex/` paths in `SKILL.md`.
  - Rewrites Compound task and agent references toward Codex custom-agent wording where possible.
- Rendered Codex custom agents under `~/.codex/agents/compound-engineering` as TOML files with:
  - `name`
  - `description`
  - `developer_instructions`
- Added a managed Compound Codex compatibility block to `~/.codex/AGENTS.md`, matching upstream converter guidance for Claude tool-name compatibility.
- Added `toolnix.compoundEngineering.codex.enable`, defaulting to `true` when Compound Engineering is enabled.
- Changed the generic `~/.agents/skills` link back to baseline-only skills so Codex does not see duplicate Pi-rendered Compound skills through its shared skill discovery path.

## Validation

Commands run:

```bash
nix flake check --no-build
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
codex debug prompt-input 'check compound assets'
```

Observed:

- `~/.codex/skills/compound-engineering` points to rendered Codex assets in the Nix store.
- `~/.codex/agents/compound-engineering` points to rendered Codex agent TOML files in the Nix store.
- `~/.codex/skills/compound-engineering/ce-code-review/SKILL.md` exists.
- `~/.codex/skills/compound-engineering/ce-update` is absent because it is Claude-only upstream.
- `~/.codex/agents/compound-engineering/ce-security-reviewer.toml` parses with Python `tomllib`.
- `codex debug prompt-input` shows Codex-discovered Compound skills from `compound-engineering-codex-assets`.
- `codex debug prompt-input` no longer shows duplicate Compound skills from `compound-engineering-pi-assets` after making `~/.agents/skills` baseline-only.
- `~/.codex/AGENTS.md` includes the managed `Compound Codex Tool Mapping` block.
- Rendered counts: `33` `ce-*` Codex skill dirs plus `lfg`, and `51` `ce-*.toml` agents.

## Caveats

- This is a declarative best-effort replacement for upstream's marketplace/TUI + Bun converter flow.
- Codex native plugin support for custom agents is still evolving upstream.
- Model-backed Codex CE workflow validation remains a follow-up.
