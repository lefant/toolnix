# Compound Engineering Toolnix Integration

**Date:** 2026-04-29
**Status:** ✅ COMPLETED
**Related research:** `docs/research/2026-04-29-compound-engineering-toolnix-integration.md`
**Related spec:** `docs/specs/compound-engineering-toolnix-integration.md`
**Related plan:** `docs/plans/2026-04-29-compound-engineering-toolnix-integration.md`

## Summary

Implemented an optional EveryInc Compound Engineering integration directly in Toolnix. Compound Engineering now enters Toolnix as its own pinned non-flake input instead of being copied into `agent-skills`. The `lefant-toolnix` Home Manager profile enables it for live validation and now exposes Pi-compatible Compound skills, agent definitions, and the Pi subagent extension declaratively.

## Implementation

- Added `compound-engineering-plugin` input pinned to `EveryInc/compound-engineering-plugin` rev `e5b397c9d1883354f03e338dd00f98be3da39f9f`.
- Exported the new input through `devenvSources` and module input forwarding.
- Added `flake-parts/features/compound-engineering.nix` with disabled-by-default Home Manager options:
  - `toolnix.compoundEngineering.enable`
  - `toolnix.compoundEngineering.skills.enable`
  - `toolnix.compoundEngineering.pi.enable`
  - `toolnix.compoundEngineering.pi.subagentExtension.enable`
- Added `modules/shared/compound-engineering.nix` to discover assets under `plugins/compound-engineering/`.
- Added `modules/shared/compound-engineering/render-pi-assets.py` to render Pi-compatible assets declaratively in a Nix build:
  - copies skill directories and applies the upstream Pi text transform to `SKILL.md`
  - converts Claude-style `.agent.md` files to Pi agent Markdown with only `name` and `description` frontmatter
  - strips Claude-style `tools`, `model`, and `color` frontmatter from Pi agent files
- Extended `modules/shared/agent-baseline.nix` to expose reusable `skillLinks` and `mkManagedSkillTree`.
- Updated Home Manager glue to compose Compound skills into the managed skill tree when enabled.
- Linked Pi-specific assets:
  - `~/.pi/agent/agents`
  - `~/.pi/agent/extensions/subagent`
- Enabled `toolnix.compoundEngineering.enable = true` only for the self-hosted `homeConfigurations.lefant-toolnix` output.

## Validation

Commands run:

```bash
nix flake check --no-build
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
```

Post-activation checks:

```bash
readlink -f ~/.pi/agent/skills
readlink -f ~/.pi/agent/agents
readlink -f ~/.pi/agent/extensions/subagent
ls -l ~/.pi/agent/skills/ce-code-review/SKILL.md
ls -l ~/.pi/agent/agents/ce-security-reviewer.md
ls -l ~/.pi/agent/extensions/subagent/index.ts
find -L ~/.pi/agent/skills -maxdepth 1 -mindepth 1 -name 'ce-*' | wc -l
find -L ~/.pi/agent/agents -maxdepth 1 -mindepth 1 -name 'ce-*.md' | wc -l
```

Observed:

- `~/.pi/agent/skills` points to `toolnix-managed-skills-with-compound-engineering`.
- `~/.pi/agent/agents` points to `toolnix-compound-engineering-pi-agents`.
- `~/.pi/agent/extensions/subagent` points to the Pi package's bundled `examples/extensions/subagent` directory.
- Pi skill count from Compound: `34` `ce-*` skills plus `lfg`.
- Pi agent count from Compound: `51` `ce-*.md` agents.
- `ce-security-reviewer.md` contains Pi-compatible frontmatter without `tools`, `model`, or `color`.

Pi startup validation in tmux:

```bash
PI_OFFLINE=1 pi --verbose
```

The startup view showed:

- Compound skills in `[Skills]`, including `ce-code-review`, `ce-work`, `ce-plan`, and others.
- `~/.pi/agent/extensions/subagent` in `[Extensions]`.

Monitor command for the validation tmux session:

```bash
tmux -S /tmp/claude-tmux-sockets/claude.sock attach -t pi-compound-test
```

## Plan vs Reality

**Planned:** Link raw Compound skills and agents from the upstream source.

**Actual:** Built Pi-specific rendered assets because upstream has a Pi converter that transforms skill content and strips Claude-specific agent frontmatter. Direct raw linking would pass Claude-style tool names such as `Read, Grep, Glob, Bash` to the Pi subagent extension, which is likely wrong for Pi.

**Planned:** Install a Pi subagent extension declaratively.

**Actual:** Linked the subagent extension bundled with the pinned Pi package from `llm-agents`, avoiding a new npm package or imperative `pi install` activation step.

## Challenges & Solutions

- **Nix lock initially failed** because `~/.cache/nix/tarball-cache-v2` existed as an empty non-git directory. Moved it aside and reran `nix flake lock --update-input compound-engineering-plugin` successfully.
- **Untracked Nix files were invisible to flake evaluation** until staged. Staged new module files before building the Home Manager activation package.
- **Upstream layout differed from earlier local WIP**. Current source is under `plugins/compound-engineering/{skills,agents}` instead of root-level `skills/` and `agents/`.

## Follow-ups

- [ ] Exercise a real model-backed Pi `subagent` tool call with a small safe task.
- [ ] Decide whether to keep Compound enabled in `homeConfigurations.lefant-toolnix` after more daily-use validation.
- [ ] Consider exposing generated Compound asset trees as flake outputs for easier inspection.
- [ ] Consider Claude/OpenCode/Codex fanout later, using upstream target converters as references.
