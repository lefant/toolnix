---
title: Agent-Native Readiness Specs by Consumption Mode
date: 2026-05-04
category: architecture-patterns
module: Toolnix readiness documentation
problem_type: architecture_pattern
component: documentation
severity: medium
applies_when:
  - "A repo needs agents to verify environment readiness from plain-language instructions"
  - "A readiness pattern from another product must be adapted without importing that product's operational assumptions"
  - "Human readers and verification agents both need to understand readiness boundaries quickly"
related_components:
  - Toolnix Home Manager host profile
  - Toolnix devenv consumer module
  - wrapped Toolnix runtime proofs
  - optional browser and host-control capabilities
tags:
  - agent-readiness
  - documentation
  - consumption-modes
  - mermaid
  - verification
  - toolnix
---

# Agent-Native Readiness Specs by Consumption Mode

## Context

Toolnix needed one canonical answer to “is this environment ready for agent-native coding?” The repo already had bootstrap scripts, smoke checks, proof docs, strategy notes, and architecture references, but those artifacts did not add up to a single readiness contract that an agent could follow or a human could scan.

The useful source pattern came from Hackbox: split readiness into deterministic smoke checks and interactive acceptance checks, then express expected behavior as plain-language scenarios. The key adaptation was to keep the validation pattern while replacing Hackbox control-host and inventory roles with Toolnix’s own consumption modes: host-only bootstrap, Home Manager host profiles, project `devenv` consumers, wrapped runtime proofs, and optional capabilities.

Session history search for the last seven days returned no relevant prior-session findings, so the documented guidance comes from the implemented spec, requirements document, plan, and current Toolnix docs rather than prior hidden attempts (session history).

## Guidance

When documenting readiness for an agent-native development environment, organize the spec around the product’s stable consumption modes and ownership boundaries, not around the source system that inspired the pattern.

For Toolnix, the durable shape is:

- **Host-only bootstrap**: remote flake bootstrap should produce Home Manager-managed Toolnix state without requiring a target-side clone.
- **Home Manager host profile**: persistent shell, tmux, git/SSH, agent config, and managed skills are host-owned state under `$HOME`.
- **Project `devenv` consumer**: project shells get shell-local Toolnix behavior without claiming ownership of persistent agent dotfiles.
- **Wrapped runtime proofs**: `toolnix-pi` and `toolnix-tmux` prove tracked runtime config can start outside a normally activated host profile.
- **Optional capabilities**: browser automation and host-control helpers are readiness areas only when explicitly enabled.

Keep three concepts separate:

1. **Expected state** — the prose requirement defining what ready means.
2. **Validation preference** — deterministic smoke, interactive acceptance, or mixed.
3. **Evidence** — command output, transcripts, or devlog notes that support a readiness claim but do not redefine the requirement.

Use a small status vocabulary so verification agents can report nuanced outcomes without false failures:

- `pass`: expected state observed.
- `fail`: expected state checked and absent.
- `blocked`: structurally plausible, but credentials, provider state, network, or another prerequisite blocked the check.
- `not applicable`: disabled optional feature or out-of-scope consumption mode.
- `not covered`: the spec names the expectation, but no current smoke or acceptance procedure exists.

Mermaid diagrams help when they summarize relationships that would otherwise require repeated prose. In the Toolnix readiness spec, two diagrams were enough:

- validation and evidence flow, showing smoke checks, interactive acceptance, statuses, and evidence;
- consumption-mode applicability, showing default/published interfaces separately from opt-in capabilities.

The prose must remain authoritative. Diagrams are reader aids, not additional requirement sources.

## Why This Matters

Agent-native readiness documentation fails if it is only a human narrative. A verification agent needs scenario-shaped instructions, explicit status vocabulary, and clear boundaries for credential-dependent checks. Without those, missing local auth, disabled optional browser support, or out-of-scope fleet inventory can be misreported as Toolnix failures.

It also fails if it blindly copies the source pattern. Hackbox’s control-host/target readiness model was useful, but Toolnix’s public contract is different. Toolnix is a Nix-first development environment and host-profile repo with published flake interfaces; it should not make inventory workflows, target-entry wrappers, or SSH assumptions part of the default readiness baseline.

Separating expected state from evidence prevents diagnostic output from becoming accidental policy. A bootstrap summary, tmux transcript, or devlog can support a readiness claim, but the spec stays the source of truth for what must be true.

## When to Apply

- Use this pattern when a repo exposes multiple setup or consumption paths and readiness differs by path.
- Use it when an agent should be able to verify an environment from documentation without bespoke maintainer explanation.
- Use it when optional features exist and their absence should report as `not applicable`, not `fail`.
- Use it when live credentials or provider access are needed for acceptance and should report as `blocked` when unavailable.
- Use it when adapting a readiness model from another product whose operational roles do not match the current repo.

## Examples

### Good: Toolnix-native framing

```markdown
### Project devenv consumer readiness

**Validation preference:** primarily deterministic smoke checks, with optional interactive acceptance for shell ergonomics.

The project consumer path SHALL provide shell-local Toolnix behavior without claiming ownership of persistent host files.

**Scenarios:**

- GIVEN a project imports the Toolnix devenv module WHEN the project shell starts THEN Toolnix-provided shell packages, aliases, env, and enabled project features are available.
- GIVEN a project shell is checked for readiness WHEN persistent files such as `~/.pi/agent/settings.json` are absent THEN that absence is **not applicable** unless the host profile is also in scope.
```

This works because it names the Toolnix interface, scopes ownership to the project shell, and prevents a verification agent from treating missing host-owned dotfiles as a project readiness failure.

### Bad: copying the source system’s roles

```markdown
### Target readiness

The target is ready when target-entry and inventory SSH wrappers can reach it.
```

That would import Hackbox inventory assumptions into Toolnix’s default contract. In Toolnix, host-control helpers are opt-in convenience behavior, and external fleet credentials remain outside the default readiness baseline.

### Evidence map pattern

Use a table to connect requirements to existing proof without making proof artifacts authoritative:

```markdown
| Readiness area | Expected state | Validation preference | Existing evidence | Coverage gap |
| --- | --- | --- | --- | --- |
| Host-only bootstrap | Fresh host reaches Home Manager-managed Toolnix state without target-side clone | mixed | bootstrap spec, VM bootstrap proof, bootstrap script | No single strict verifier for every bootstrap summary line |
```

This lets future maintainers see where automated checks already exist and where a later conformance runner could fill gaps.

## Related

- [`docs/specs/toolnix-agent-readiness.md`](../../specs/toolnix-agent-readiness.md)
- [`docs/brainstorms/2026-05-04-toolnix-agent-readiness-requirements.md`](../../brainstorms/2026-05-04-toolnix-agent-readiness-requirements.md)
- [`docs/plans/2026-05-05-002-feat-toolnix-agent-readiness-plan.md`](../../plans/2026-05-05-002-feat-toolnix-agent-readiness-plan.md)
- [`STRATEGY.md`](../../../STRATEGY.md)
- [`docs/reference/architecture.md`](../../reference/architecture.md)
- Related existing solution: [`docs/solutions/tooling-decisions/nix-browser-tool-cache-friendly-repack-2026-05-05.md`](../tooling-decisions/nix-browser-tool-cache-friendly-repack-2026-05-05.md) documents an adjacent Toolnix boundary rule: browser automation remains opt-in and cache-conscious.
