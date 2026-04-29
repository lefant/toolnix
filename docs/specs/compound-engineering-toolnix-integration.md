# Compound Engineering Toolnix Integration

## Purpose

Toolnix SHALL provide an optional declarative integration for EveryInc Compound Engineering so hosts can use its skills and Pi subagents without folding the custom plugin bundle into `agent-skills` or running imperative installers.

## Requirements

### Default bundle activation

The system SHALL enable Compound Engineering by default for Home Manager hosts while preserving an explicit opt-out option.

**Scenarios:**
- GIVEN a default Toolnix Home Manager host WHEN Home Manager activates with the agent baseline enabled THEN Compound Engineering skills and Pi agents are linked from Nix-managed sources.
- GIVEN a host disables Compound Engineering WHEN Home Manager activates THEN Compound Engineering skills and agents are not installed by this integration.

### Direct upstream source

The system SHALL consume Compound Engineering as a direct flake input separate from `agent-skills`.

**Scenarios:**
- GIVEN Toolnix evaluates its flake WHEN inputs are resolved THEN the Compound Engineering source is available as a pinned non-flake input.
- GIVEN `agent-skills` is updated independently WHEN Compound Engineering remains unchanged THEN the Compound bundle revision does not move.

### Declarative skill fanout

The system SHALL expose Compound Engineering skill directories through the same managed skill fanout used by other agent skills when the integration is enabled.

**Scenarios:**
- GIVEN Compound Engineering is enabled WHEN Home Manager links agent files THEN Pi can discover `ce-*` skills under `~/.pi/agent/skills`.
- GIVEN Compound Engineering is disabled WHEN Home Manager links agent files THEN no `ce-*` skills are added by this integration.

### Pi subagent support

The system SHALL install Compound Engineering agent definitions and Pi subagent runtime support when Pi support is enabled.

**Scenarios:**
- GIVEN Compound Engineering Pi support is enabled WHEN Home Manager activates THEN `~/.pi/agent/agents` contains Pi-compatible Compound agent Markdown files.
- GIVEN Compound Engineering Pi support is enabled WHEN Pi starts THEN the subagent extension is present under `~/.pi/agent/extensions/subagent`.
- GIVEN Pi loads the subagent extension WHEN a task requires a specialized reviewer THEN Pi can call the `subagent` tool with a Compound agent name.

### No imperative installer in activation

The system SHALL NOT run upstream network installers or converters during Home Manager activation.

**Scenarios:**
- GIVEN Home Manager activates offline WHEN Compound Engineering is enabled THEN activation uses pinned Nix-store sources only.
- GIVEN upstream install commands exist WHEN Toolnix config is evaluated THEN they are not executed as activation side effects.

## Open Questions

- [x] Should Compound Engineering be enabled on `lefant-toolnix` by default after validation, or remain available but off? Decision: enable by default for Home Manager hosts after successful Pi validation.
- [ ] Should Toolnix normalize Claude-style agent tool names for Pi if testing shows problems?
- [ ] Should Claude or OpenCode fanout be added after Pi validation?
