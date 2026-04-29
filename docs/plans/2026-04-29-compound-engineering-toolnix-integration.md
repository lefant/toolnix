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
   - Write research, spec, and this plan.
   - Commit docs before code changes.

2. Flake input
   - Add `compound-engineering-plugin` as a non-flake input in `flake.nix`.
   - Include it in public `devenvSources` and module input forwarding.
   - Update `flake.lock`.

3. Shared Compound module
   - Add `modules/shared/compound-engineering.nix`.
   - Resolve the Compound input from module args or `toolnix.devenvSources` fallback.
   - Discover skill directories from `${compoundSrc}/skills`.
   - Discover agent files from `${compoundSrc}/agents`.
   - Expose `skillLinks`, `managedSkillTree`, `managedAgentTree`, and Pi subagent extension source.

4. Feature registry and options
   - Add `flake-parts/features/compound-engineering.nix`.
   - Add Home Manager options:
     - `toolnix.compoundEngineering.enable`
     - `toolnix.compoundEngineering.skills.enable`
     - `toolnix.compoundEngineering.pi.enable`
     - `toolnix.compoundEngineering.pi.subagentExtension.enable`
   - Default all Compound options off except nested defaults that apply once the top-level feature is enabled.

5. Home Manager fanout
   - Import the new option module in the Home Manager profile.
   - Link Compound skills into Pi's skill directory when enabled.
   - Link Compound agents into `~/.pi/agent/agents` when Pi support is enabled.
   - Link the Pi subagent extension into `~/.pi/agent/extensions/subagent` when enabled.
   - Avoid changing existing `agent-skills` behavior.

6. Validation
   - Evaluate/build the self-hosted Home Manager config.
   - Enable Compound Engineering on `lefant-toolnix` for live validation.
   - Activate Home Manager locally.
   - Confirm symlinks:
     - `~/.pi/agent/skills/ce-code-review/SKILL.md`
     - `~/.pi/agent/agents/ce-security-reviewer.agent.md`
     - `~/.pi/agent/extensions/subagent/index.ts`
   - Start Pi in tmux and verify startup/resource loading.
   - Ask Pi to list or recognize available Compound skills/subagent tool if practical.

7. Devlog and commit
   - Record implementation results in `docs/devlog/`.
   - Commit implementation and devlog in small reviewable increments.

## Non-goals

- Do not move Compound Engineering into `agent-skills`.
- Do not run upstream `bunx` installers during Home Manager activation.
- Do not generalize a portable agent-definition registry until another source needs it.
- Do not add OpenCode or Claude agent fanout until Pi behavior is validated.

## Rollback

- Disable `toolnix.compoundEngineering.enable` to remove runtime fanout.
- Revert the flake input and module additions if upstream layout or Pi extension compatibility is not usable.
