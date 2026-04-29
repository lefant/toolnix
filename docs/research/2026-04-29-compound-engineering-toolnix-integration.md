# Compound Engineering Toolnix Integration Research

## Context

EveryInc publishes Compound Engineering as a multi-agent coding bundle, not as a plain portable skill pack. The bundle includes skill directories, subagent/persona definitions, and target-specific install/conversion logic. Toolnix already manages portable skills from `github:lefant/agent-skills`, but that repo should remain a boring cross-agent skill source instead of absorbing a custom upstream plugin layout.

## Source shape

The relevant upstream source is `github:EveryInc/compound-engineering-plugin`.

The current upstream plugin lives under `plugins/compound-engineering/` and has this practical shape:

- `skills/ce-*` skill directories with `SKILL.md`
- `agents/*.agent.md` subagent/persona definitions
- plugin metadata for specific coding agents
- installer/converter behavior for targets such as Pi

The local WIP confirmed approximate scale:

- 35 skills
- 51 agent files

Example agent files use Markdown with YAML frontmatter:

```yaml
---
name: ce-security-reviewer
description: Reviews diffs for exploitable security issues.
model: inherit
tools: Read, Grep, Glob, Bash
color: red
---
```

The Markdown body is the system prompt/persona.

## Existing Toolnix behavior

`modules/shared/agent-baseline.nix` currently builds a managed skill tree from `agent-skills`:

- direct children of `${agentSkillsPath}/lefant`
- direct children of `${agentSkillsPath}/vendor/<org>`

Home Manager links that tree to multiple agents:

- `~/.agents/skills`
- `~/.claude/skills`
- `~/.config/opencode/skills`
- `~/.config/amp/skills`
- `~/.openclaw/skills`
- `~/.pi/agent/skills`

This works for plain skill directories. It does not model agent definitions or nested plugin layouts.

Historical setup-hook behavior that imperatively installed converted Compound assets was removed in `docs/devlog/2026-03-28-remove-setup-hook.md`. New integration should stay declarative and Nix-managed.

## Pi support findings

Pi supports TypeScript extensions under:

- `~/.pi/agent/extensions/*.ts`
- `~/.pi/agent/extensions/*/index.ts`
- project-local `.pi/extensions/*`

Pi includes an example `subagent` extension in its installed examples. That extension:

- registers a `subagent` tool
- discovers user agents from `path.join(getAgentDir(), "agents")`, which resolves under `~/.pi/agent/agents`
- discovers project agents from nearest `.pi/agents`
- parses Markdown frontmatter fields `name`, `description`, `tools`, and `model`
- uses the body as `systemPrompt`
- spawns isolated `pi` processes for single, parallel, or chained subagent tasks

This means Compound's `.agent.md` files are close enough to Pi's example format to use directly, with Toolnix installing both:

- `~/.pi/agent/agents/*.agent.md`
- `~/.pi/agent/extensions/subagent/{index.ts,agents.ts}`

## Design implication

Do not generalize `agent-skills` yet. There is only one known source needing subagent definitions, and Compound Engineering has custom target behavior. Toolnix is already the integration layer for agent CLIs, so Compound should be a direct Toolnix flake input and optional feature.

This preserves boundaries:

- `agent-skills`: portable skills only
- `claude-code-plugins`: Claude-specific plugin source
- `compound-engineering-plugin`: special upstream bundle consumed by Toolnix
- Toolnix: declarative fanout/adaptation layer

## Risks

- Pi's subagent extension is an example, not a stable built-in API. Toolnix should vendor/copy only the minimum extension code and be ready to adjust on Pi upgrades.
- Compound agent tool names are Claude-style (`Read`, `Grep`, `Glob`, `Bash`) while Pi tools are lowercase. The current Pi example only passes tool names into prompts/subprocess arguments; verification must confirm whether direct use is acceptable or normalization is needed.
- Installing 35+ skills and 50+ agents into the default environment could add noise. The feature should be disabled by default.
- Running upstream `bunx @every-env/compound-plugin install` during activation would reintroduce imperative network setup. Avoid it.

## Recommendation

Add an optional Toolnix feature backed by a new flake input:

```nix
compound-engineering-plugin = {
  url = "github:EveryInc/compound-engineering-plugin";
  flake = false;
};
```

The feature should:

1. discover skill directories under the upstream `plugins/compound-engineering/skills/` directory;
2. link them into the managed skill tree only when enabled;
3. discover `agents/*.agent.md`;
4. link those to `~/.pi/agent/agents` when Pi support is enabled;
5. install a Pi subagent extension declaratively;
6. remain disabled by default.
