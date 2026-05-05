---
date: 2026-05-05
topic: browser-tools
---

# Browser Tools Bundle

## Summary

Toolnix will provide a one-stop `toolnix.browserTools.enable` option for browser automation workflows, and `toolnix.agentBrowser.enable` will switch to the Nix-packaged `agent-browser` instead of the current lazy npm wrapper. Both `agent-browser` and `vhs` will use Toolnix's `pkgs.chromium` as the shared browser runtime.

---

## Problem Frame

Toolnix currently has a narrow opt-in `agent-browser` wrapper that lazily installs the real CLI through npm, while Compound Engineering skills can suggest browser-adjacent tools such as `agent-browser` and `vhs`. `vhs` depends on a Chromium-sized runtime, which is why it was intentionally excluded from the default Compound Engineering helper-tool bundle.

This creates a split first-run story: users can opt into `agent-browser`, but browser runtime provisioning and terminal demo tooling remain separate concerns. Now that `llm-agents.nix` already packages `agent-browser`, Toolnix can make browser automation fully Nix-managed without taking on a bespoke package-maintenance burden.

---

## Actors

- A1. Toolnix host user: Enables persistent browser automation tools through the Home Manager profile.
- A2. Project consumer: Enables browser automation tools inside a project `devenv` shell.
- A3. Coding agent: Uses `agent-browser` and may suggest `vhs` for browser or demo workflows.
- A4. Toolnix maintainer: Keeps defaults light while offering a clear heavy opt-in path.

---

## Key Flows

- F1. Narrow agent-browser enablement
  - **Trigger:** A host or project sets `toolnix.agentBrowser.enable = true`.
  - **Actors:** A1 or A2, A3
  - **Steps:** The environment provides the Nix-packaged `agent-browser`; browser runtime configuration points it at Toolnix's shared Chromium package; no npm first-run install is required.
  - **Outcome:** `agent-browser` is usable from the environment as a declarative Nix-managed tool.
  - **Covered by:** R1, R2, R3

- F2. Full browser tools enablement
  - **Trigger:** A host or project sets `toolnix.browserTools.enable = true`.
  - **Actors:** A1 or A2, A3
  - **Steps:** The environment provides `agent-browser`, `vhs`, and Chromium; both browser-facing tools resolve to the same Toolnix Chromium package; user guidance avoids the old browser download step.
  - **Outcome:** Browser automation and terminal demo capture are available through one opt-in switch.
  - **Covered by:** R4, R5, R6, R7

---

## Requirements

**Agent-browser packaging**
- R1. `toolnix.agentBrowser.enable` must install the Nix-packaged `agent-browser` from the existing `llm-agents.nix` input rather than using a lazy npm wrapper.
- R2. `toolnix.agentBrowser.enable` must configure `agent-browser` to use Toolnix's `pkgs.chromium` as its browser executable.
- R3. `toolnix.agentBrowser.enable` must not require `agent-browser install` or any npm network installation during normal first-run use.

**Browser tools bundle**
- R4. Toolnix must add a `toolnix.browserTools.enable` option for both Home Manager host profiles and project `devenv` consumers.
- R5. `toolnix.browserTools.enable` must provide `agent-browser`, `vhs`, and Chromium as one opt-in browser automation bundle.
- R6. `toolnix.browserTools.enable` must imply the behavior of `toolnix.agentBrowser.enable`; users should not need to set both options.
- R7. `vhs` and `agent-browser` must use the same Toolnix `pkgs.chromium` package when browser tools are enabled.

**Default weight and compatibility**
- R8. Compound Engineering's default helper-tool bundle must remain light and must not include `vhs` or Chromium through `toolnix.compoundEngineering.tools.enable`.
- R9. Existing consumers that do not enable `toolnix.agentBrowser.enable` or `toolnix.browserTools.enable` must not receive Chromium, `vhs`, or browser runtime state changes.
- R10. Documentation must distinguish the narrow `agentBrowser` option from the full `browserTools` bundle and must update first-run guidance to remove the old npm/browser-install path for Nix-managed usage.

---

## Acceptance Examples

- AE1. **Covers R1, R2, R3.** Given a project enables only `toolnix.agentBrowser.enable`, when the shell starts, `agent-browser` is on `PATH`, uses the configured Nix Chromium executable, and does not need an npm install or `agent-browser install` before ordinary use.
- AE2. **Covers R4, R5, R6, R7.** Given a host enables `toolnix.browserTools.enable`, when Home Manager activates, `agent-browser`, `vhs`, and Chromium are available, and both browser-facing tools use Toolnix's `pkgs.chromium` rather than separate Chromium derivations.
- AE3. **Covers R8, R9.** Given a default Compound Engineering-enabled host with no browser-tool opt-in, when Home Manager activates, `ast-grep` and `silicon` remain available but `vhs` and Chromium are not added by the Compound helper bundle.

---

## Success Criteria

- Users have one obvious heavy opt-in switch for browser automation and demo capture.
- `agent-browser` becomes declarative and Nix-managed in Toolnix, eliminating npm first-run failure modes.
- Browser runtime closure weight remains opt-in and does not surprise default Compound Engineering users.
- Planning can proceed without deciding whether Chromium should come from `llm-agents.nix` or Toolnix: the chosen shared source is Toolnix's `pkgs.chromium`.

---

## Scope Boundaries

- Do not make browser tools default-on.
- Do not put `vhs` or Chromium into the default Compound Engineering helper-tool bundle.
- Do not keep the lazy npm wrapper as the implementation for `toolnix.agentBrowser.enable`.
- Do not share browser profiles, sessions, or state between `agent-browser` and `vhs`; only the browser executable package is shared.
- Do not force `llm-agents.nix` to follow Toolnix's nixpkgs input globally, because that could affect unrelated coding-agent packages.

---

## Key Decisions

- Use `toolnix.browserTools.enable` as the one-stop bundle name: This preserves the narrower existing agent-browser concept while making the heavy browser toolchain discoverable.
- Fully switch `toolnix.agentBrowser.enable` to Nix-packaged `agent-browser`: The package already exists in `llm-agents.nix`, which Toolnix already trusts for coding-agent packages.
- Use Toolnix's `pkgs.chromium` as the shared browser source: This keeps browser runtime selection under Toolnix's main package set and lets both `agent-browser` and `vhs` align on one Chromium derivation.
- Keep Compound Engineering helper tools light: Browser tooling is useful for some CE skills, but Chromium's closure size warrants an explicit browser opt-in.

---

## Dependencies / Assumptions

- `llm-agents.nix` continues to expose an `agent-browser` package for the supported Toolnix system.
- The `agent-browser` package can be reused or overridden so that its browser executable points at Toolnix's `pkgs.chromium`.
- The nixpkgs `vhs` package remains overrideable with a caller-selected Chromium package.
- Documentation and checks should make accidental duplicate Chromium sources visible during implementation.

---

## Outstanding Questions

### Deferred to Planning

- [Affects R2, R7][Technical] Determine the cleanest way to make the `llm-agents.nix` `agent-browser` package use Toolnix's `pkgs.chromium`: direct package override, callPackage of the upstream package file, wrapper layering, or upstream package parameterization.
- [Affects R4][Technical] Decide whether the new browser tools feature should live as a new shared module, a flake-parts feature, or both, following the existing dendritic feature layout.
- [Affects R10][Needs research] Verify which smoke tests are cheap enough for CI or local flake checks without launching a full browser.
