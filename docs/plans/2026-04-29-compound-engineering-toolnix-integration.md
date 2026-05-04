# Plan: Compound Engineering Toolnix Integration

## Goal

Add a Toolnix integration for EveryInc Compound Engineering as a direct flake input. Keep `agent-skills` portable and skill-only while enabling Compound skills and target-specific agent assets by default for Home Manager hosts.

The rollout is Pi-first, then declarative best-effort fanout for OpenCode, Claude Code, and Codex CLI after Pi validation succeeds. All target support must avoid imperative upstream installers during Home Manager activation.

## Success Criteria

- A Home Manager user gets usable Compound Engineering skills and agent assets without manual plugin installation.
- Pi can invoke Compound skills and at least one model-backed Compound subagent from a normal Toolnix-managed host session.
- OpenCode, Claude Code, and Codex CLI receive target-specific assets that validate with their available local inspection commands.
- Default-on remains acceptable for daily Toolnix use: users can discover and use the Compound workflow without excessive duplicate skill noise or broken target-specific skills.
- Every default-on path has a documented opt-out and validation evidence.

## References

- Research: `docs/research/2026-04-29-compound-engineering-toolnix-integration.md`
- Spec: `docs/specs/compound-engineering-toolnix-integration.md`
- Integration devlog: `docs/devlog/2026-04-29-compound-engineering-toolnix-integration.md`
- Pi validation devlog entries: `docs/devlog/2026-04-29-compound-engineering-toolnix-integration.md`
- OpenCode devlog: `docs/devlog/2026-04-29-compound-engineering-opencode-default.md`
- Claude Code devlog: `docs/devlog/2026-04-29-compound-engineering-claude-default.md`
- Codex CLI devlog: `docs/devlog/2026-04-29-compound-engineering-codex-default.md`
- Review-fix devlog: `docs/devlog/2026-04-29-compound-engineering-review-fixes.md`
- Existing skill fanout: `modules/shared/agent-baseline.nix`
- Existing Home Manager glue: `internal/profiles/home-manager/core.nix`
- Compound module: `modules/shared/compound-engineering.nix`
- Pi extension docs: `/nix/store/.../pi-coding-agent/docs/extensions.md`
- Pi subagent example: `/nix/store/.../pi-coding-agent/examples/extensions/subagent/`

## Implementation Steps

1. Documentation baseline
   - [x] Write research, spec, and this plan.
   - [x] Commit docs before code changes.

2. Flake input
   - [x] Add `compound-engineering-plugin` as a non-flake input in `flake.nix`.
   - [x] Include it in public `devenvSources` and module input forwarding so downstream modules using Toolnix's published interface receive the same pinned source.
   - [x] Update `flake.lock`.

3. Shared Compound module
   - [x] Add `modules/shared/compound-engineering.nix`.
   - [x] Resolve the Compound input from module args or `toolnix.devenvSources` fallback.
   - [x] Discover skill directories from `${compoundSrc}/plugins/compound-engineering/skills`.
   - [x] Discover agent files from `${compoundSrc}/plugins/compound-engineering/agents`.
   - [x] Expose Pi-rendered skill links, raw Claude skill links, OpenCode skill links, Codex asset paths, agent trees, and the Pi subagent extension source.
   - [x] Add build-time asset validation for load-bearing upstream layout and generated Codex TOML.

4. Feature registry and options
   - [x] Add `flake-parts/features/compound-engineering.nix`.
   - [x] Add Home Manager options:
     - `toolnix.compoundEngineering.enable`
     - `toolnix.compoundEngineering.skills.enable`
     - `toolnix.compoundEngineering.tools.enable`
     - `toolnix.compoundEngineering.pi.enable`
     - `toolnix.compoundEngineering.pi.subagentExtension.enable`
     - `toolnix.compoundEngineering.opencode.enable`
     - `toolnix.compoundEngineering.claude.enable`
     - `toolnix.compoundEngineering.codex.enable`
   - [x] Default Compound Engineering on for Home Manager hosts after validation, with explicit opt-out via `toolnix.compoundEngineering.enable = false`.
   - [x] Keep `skills.enable` as the skill-tree gate; target `*.enable` flags also control target-specific agents/extensions.
   - [x] Add default-on `tools.enable` to install native helper tools preferred by Compound Engineering agents without including heavyweight `vhs`.

5. Home Manager fanout
   - [x] Import the new option module in the Home Manager profile.
   - [x] Link Compound skills into the managed Pi/agent skill tree when enabled.
   - [x] Link Compound agents into `~/.pi/agent/agents` when Pi support is enabled.
   - [x] Link the Pi subagent extension into `~/.pi/agent/extensions/subagent` when enabled.
   - [x] Link OpenCode-specific skills and agents into `~/.config/opencode/skills` and `~/.config/opencode/agents`.
   - [x] Link Claude-native upstream skills and agents into `~/.claude/skills` and `~/.claude/agents`.
   - [x] Link Codex-specific skills and custom-agent TOML into `~/.codex/skills/compound-engineering` and `~/.codex/agents/compound-engineering`.
   - [x] Compose the managed Compound Codex compatibility block into `~/.codex/AGENTS.md`.
   - [x] Keep generic `~/.agents/skills` baseline-only to avoid duplicate Codex discovery of Pi-rendered Compound skills.
   - [x] Avoid changing existing `agent-skills` behavior beyond refreshing the pinned baseline input.
   - [x] Install Compound helper tools (`ast-grep`, `silicon`) into Home Manager host packages when Compound Engineering tools are enabled.

6. Project shell support
   - [x] Add a devenv-side `toolnix.compoundEngineering` option namespace.
   - [x] Install Compound helper tools (`ast-grep`, `silicon`) into Toolnix project shells when Compound Engineering tools are enabled.

7. Target renderers
   - [x] Add Pi renderer for Pi-compatible skills and agents.
   - [x] Add OpenCode renderer for OpenCode-compatible skills and subagent markdown.
   - [x] Add Codex renderer for Codex-compatible skills and custom-agent TOML.
   - [x] Preserve Claude Code's native upstream assets without converting frontmatter.
   - [x] Filter target-specific skills with upstream `ce_platforms` so Claude-only skills such as `ce-update` do not appear in OpenCode or Codex.
   - [x] Validate every generated Codex agent TOML file during Nix build.

8. Validation
   - [x] Evaluate/build the self-hosted Home Manager config.
   - [x] Enable Compound Engineering on `lefant-toolnix` through the default Home Manager option.
   - [x] Activate Home Manager locally.
   - [x] Confirm Pi symlinks:
     - `~/.pi/agent/skills/ce-code-review/SKILL.md`
     - `~/.pi/agent/agents/ce-security-reviewer.md`
     - `~/.pi/agent/extensions/subagent/index.ts`
   - [x] Start Pi in tmux and verify startup/resource loading.
   - [x] Exercise a real `subagent` tool call through a model-backed Pi session.
   - [x] Run `/ce-compound` against a throwaway prime-sieve project and validate generated documentation.
   - [x] Validate OpenCode asset loading with `opencode agent list`.
   - [x] Validate Claude Code plugin/assets with `claude plugin validate` and raw asset checks.
   - [x] Validate Codex asset discovery with `codex debug prompt-input`.
   - [x] Verify `ce-update` is absent from non-Claude target skill trees.
   - [x] Verify `toolnix.compoundEngineering.skills.enable = false` suppresses Compound skill trees while preserving target-specific agent assets.
   - [x] Verify activation/build paths do not invoke upstream marketplace, TUI, `bunx`, `npm`, `curl`, or other network installers.
   - [x] Add flake checks for target asset rendering and the skills opt-out matrix.

9. Devlog and commits
   - [x] Record implementation results in `docs/devlog/`.
   - [x] Commit implementation and devlog in small reviewable increments.
   - [x] Commit and devlog OpenCode, Claude Code, and Codex CLI fanout separately.
   - [x] Commit and devlog review fixes and validation hardening.

## Non-goals

- Do not move Compound Engineering into `agent-skills`.
- Do not run upstream `bunx` installers, marketplace installs, or TUI plugin setup during Home Manager activation.
- Do not generalize a portable agent-definition registry until another source needs it.
- Do not claim full native plugin parity for OpenCode or Codex while their plugin/custom-agent support is still evolving; this integration is declarative best-effort fanout from pinned upstream assets.
- Do not assume model-backed workflows for OpenCode, Claude Code, and Codex CLI are fully validated until separate daily-use validation records them.

## Rollback and Opt-Out

- Set `toolnix.compoundEngineering.enable = false` to remove all Compound fanout.
- Set `toolnix.compoundEngineering.skills.enable = false` to remove Compound skill trees while keeping target-specific agent assets available where the target integration remains enabled.
- Set `toolnix.compoundEngineering.tools.enable = false` to remove Compound helper tools (`ast-grep`, `silicon`) while keeping skills and agent assets enabled.
- Set per-target flags to disable individual fanout paths:
  - `toolnix.compoundEngineering.pi.enable = false`
  - `toolnix.compoundEngineering.opencode.enable = false`
  - `toolnix.compoundEngineering.claude.enable = false`
  - `toolnix.compoundEngineering.codex.enable = false`
- Revert the flake input and module additions if upstream layout or target compatibility is not usable.

## Follow-ups

- Continue daily-use validation of default-on Compound Engineering on `lefant-toolnix`.
- Run model-backed OpenCode, Claude Code, and Codex CLI workflows against small real tasks.
- Watch upstream Compound Engineering and target plugin/custom-agent formats; simplify renderers when native support stabilizes.
