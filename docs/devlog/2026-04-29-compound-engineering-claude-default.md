# Compound Engineering Claude Code Default Integration

**Date:** 2026-04-29
**Status:** ✅ COMPLETED

## Summary

Added best-effort default Claude Code support for the Toolnix Compound Engineering integration. This follows upstream Claude Code install guidance (`/plugin marketplace add EveryInc/compound-engineering-plugin`, then `/plugin install compound-engineering`) by exposing the same pinned upstream Claude-native skill and agent assets declaratively instead of invoking the interactive plugin marketplace flow during activation.

## Implementation

- Added Claude-specific Compound fanout behind `toolnix.compoundEngineering.claude.enable`, defaulting to `true` when Compound Engineering is enabled.
- Added a raw upstream Compound agent link tree for Claude Code.
- Changed `~/.claude/skills` to use Claude-native upstream Compound skills instead of the Pi-rendered skill tree.
- Linked Claude agents to `~/.claude/agents` with normalized filenames while preserving the upstream Claude frontmatter and body.

## Validation

Commands run:

```bash
nix flake check --no-build
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
claude plugin validate /nix/store/vc1c0ay18xz66fvq63k4rrz08cv20sfk-source/plugins/compound-engineering
```

Observed:

- `~/.claude/skills` points to `toolnix-managed-claude-skills-with-compound-engineering`.
- `~/.claude/agents` points to `toolnix-compound-engineering-claude-agents`.
- `~/.claude/skills/ce-code-review/SKILL.md` exists.
- `~/.claude/skills/ce-update/SKILL.md` exists, preserving the Claude-only upstream skill.
- `~/.claude/agents/ce-security-reviewer.md` preserves upstream Claude Code frontmatter such as `model: inherit`, `tools: Read, Grep, Glob, Bash`, and `color: blue`.
- `claude plugin validate` passed against the pinned upstream plugin directory.

## Caveats

- This avoids the interactive upstream plugin marketplace install during activation.
- Validation confirms the assets and upstream plugin manifest are valid. A model-backed Claude Code `/ce-*` workflow run remains a follow-up.
