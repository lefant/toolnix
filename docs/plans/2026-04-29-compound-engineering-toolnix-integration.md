# Plan: Compound Engineering Toolnix Integration

## Goal

Add a disabled-by-default Toolnix integration for EveryInc Compound Engineering as a direct flake input. Keep `agent-skills` portable and skill-only while allowing `lefant-toolnix` to opt into Compound skills and Pi subagents declaratively.

## References

- Research: `docs/research/2026-04-29-compound-engineering-toolnix-integration.md`
- Spec: `docs/specs/compound-engineering-toolnix-integration.md`
- Existing skill fanout: `modules/shared/agent-baseline.nix`
- Existing Home Manager glue: `internal/profiles/home-manager/core.nix`
- Pi extension docs: `/nix/store/.../pi-coding-agent/docs/extensions.md`
- Pi subagent example: `/nix/store/.../pi-coding-agent/examples/extensions/subagent/`

## Implementation Steps

1. Documentation baseline
   - [x] Write research, spec, and this plan.
   - [x] Commit docs before code changes.

2. Flake input
   - [x] Add `compound-engineering-plugin` as a non-flake input in `flake.nix`.
   - [x] Include it in public `devenvSources` and module input forwarding.
   - [x] Update `flake.lock`.

3. Shared Compound module
   - [x] Add `modules/shared/compound-engineering.nix`.
   - [x] Resolve the Compound input from module args or `toolnix.devenvSources` fallback.
   - [x] Discover skill directories from `${compoundSrc}/plugins/compound-engineering/skills`.
   - [x] Discover agent files from `${compoundSrc}/plugins/compound-engineering/agents`.
   - [x] Expose `skillLinks`, `managedSkillTree`, `managedAgentTree`, and Pi subagent extension source.

4. Feature registry and options
   - [x] Add `flake-parts/features/compound-engineering.nix`.
   - [x] Add Home Manager options:
     - `toolnix.compoundEngineering.enable`
     - `toolnix.compoundEngineering.skills.enable`
     - `toolnix.compoundEngineering.pi.enable`
     - `toolnix.compoundEngineering.pi.subagentExtension.enable`
   - [x] Default all Compound options off except nested defaults that apply once the top-level feature is enabled.

5. Home Manager fanout
   - [x] Import the new option module in the Home Manager profile.
   - [x] Link Compound skills into the managed skill tree when enabled.
   - [x] Link Compound agents into `~/.pi/agent/agents` when Pi support is enabled.
   - [x] Link the Pi subagent extension into `~/.pi/agent/extensions/subagent` when enabled.
   - [x] Avoid changing existing `agent-skills` behavior.

6. Validation
   - [x] Evaluate/build the self-hosted Home Manager config.
   - [x] Enable Compound Engineering on `lefant-toolnix` for live validation.
   - [x] Activate Home Manager locally.
   - [x] Confirm symlinks:
     - `~/.pi/agent/skills/ce-code-review/SKILL.md`
     - `~/.pi/agent/agents/ce-security-reviewer.md`
     - `~/.pi/agent/extensions/subagent/index.ts`
   - [x] Start Pi in tmux and verify startup/resource loading.
   - [x] Exercise a real `subagent` tool call through a model-backed Pi session.
   - [x] Run `/ce-compound` against a throwaway prime-sieve project and validate generated documentation.

7. Devlog and commit
   - [x] Record implementation results in `docs/devlog/`.
   - [x] Commit implementation and devlog in small reviewable increments.

## Non-goals

- Do not move Compound Engineering into `agent-skills`.
- Do not run upstream `bunx` installers during Home Manager activation.
- Do not generalize a portable agent-definition registry until another source needs it.
- Do not add OpenCode or Claude agent fanout until Pi behavior is validated.

## Rollback

- Disable `toolnix.compoundEngineering.enable` to remove runtime fanout.
- Revert the flake input and module additions if upstream layout or Pi extension compatibility is not usable.
