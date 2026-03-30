# Plan: flake-parts + internal auto-import pilot on required-baseline

## Goal

Introduce `flake-parts` internally in `toolnix`, add an internal auto-import mechanism for flake-part modules, and pilot the migration on `modules/shared/required-baseline.nix` first.

The first pass must keep current public outputs stable and validate against the self-hosted `lefant-toolnix` workflow before any wider migration.

## Scope

In scope:

- internal `flake-parts` adoption
- internal auto-import for flake-part modules
- pilot migration of `required-baseline`
- preserving current public flake outputs and module paths
- validation on `lefant-toolnix`

Out of scope:

- redesigning public consumer interfaces
- downstream consumer-host optimization
- control-host or inventory concerns
- migrating other shared modules in the first pass

## Current baseline

Current public outputs that must remain stable:

- `homeConfigurations.lefant-toolnix`
- `homeManagerModules.default`
- `devenvSources`
- `devenvModules.default`

Current self-hosted checks that must keep working:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

Current pilot target:

- `modules/shared/required-baseline.nix`

Reason for choosing it first:

- small surface area
- used by both host and project paths
- low risk compared with shell-heavy or agent-heavy layers

## Target outcome

After the pilot:

- `flake.nix` is internally structured with `flake-parts`
- flake-part modules are loaded through an internal auto-import mechanism
- only `required-baseline` is routed through that new internal path
- public outputs and self-hosted behavior remain unchanged

## Proof-of-migration checkpoint

Do not widen the migration beyond `required-baseline` until this checkpoint passes.

The checkpoint passes only if all of the following are true:

### Public outputs are unchanged

- `homeConfigurations.lefant-toolnix` still exists and builds
- `homeManagerModules.default` still resolves
- `devenvSources` still exposes the expected inputs
- `devenvModules.default` still works for the self-hosted shell path

### Self-hosted workflow still works on `lefant-toolnix`

Run:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

Then verify baseline tool presence interactively:

```bash
command -v mg
command -v bat
command -v tmux
command -v just
locale
```

### Public paths stay stable

- no change to `modules/devenv/project.nix`
- no public-output rename
- no consumer-facing path churn in README examples

## Implementation steps

### Step 1 — Introduce flake-parts conservatively

- add `flake-parts` as a flake input
- convert `flake.nix` to `flake-parts.lib.mkFlake`
- preserve the current top-level public outputs exactly
- keep the first conversion thin; do not mix in unrelated cleanup

### Step 2 — Add internal auto-import

- add a dedicated internal directory for flake-part modules
- add a small auto-import helper for that directory
- keep the mechanism internal-only
- do not apply auto-import broadly across `modules/`

### Step 3 — Pilot required-baseline

- route only `required-baseline` through the new internal flake-parts structure
- keep `modules/shared/required-baseline.nix` stable at its existing call sites, using a compatibility wrapper if needed
- ensure host and project paths still receive the same effective package/env values

Do not migrate yet:

- `opinionated-shell`
- `agent-baseline`
- `agent-browser`
- `host-control`

### Step 4 — Run the checkpoint

Run the required build and shell checks, then do the interactive baseline-tool smoke test on `lefant-toolnix`.

Record exactly what stayed stable:

- output names
- build commands
- shell entry behavior
- required-baseline tool availability

### Step 5 — Stop or widen based on the checkpoint

If the checkpoint passes:

- write a devlog with the proof result and any compatibility constraints
- create a follow-on plan for the next internal layer(s)

If the checkpoint fails:

- stop at `required-baseline`
- document the mismatch
- narrow or revert until public outputs and self-hosted behavior match the pre-migration baseline

## Risks and controls

### Risk: flake-parts conversion changes public outputs

Control:

- preserve exact top-level output names first
- validate immediately after introducing `flake-parts`

### Risk: auto-import adds hidden coupling

Control:

- keep the auto-import directory small and internal-only
- use it only for flake-parts internals in the pilot

### Risk: pilot scope expands too early

Control:

- keep the first migration limited to `required-baseline`
- block widening until the checkpoint passes

### Risk: self-hosted behavior drifts without obvious build failure

Control:

- require both build validation and interactive shell validation
- explicitly check `required-baseline` tools

## Current status

Implementation now includes a completed flake-parts-owned proof for the Home Manager consumer path:

- `homeConfigurations.lefant-toolnix` is built from a flake-parts-owned internal profile module
- `homeManagerModules.default` exports that same composed module
- `modules/home-manager/toolnix-host.nix` remains as a compatibility wrapper

Still pending for this plan:

- remote rollout and verification on `lefant-toolnix`
- remote rollout and verification on `lefant-toolbox-nix`
- remote rollout and verification on `lefant-toolbox-nix2`
- remote rollout and verification on `lefant-toolbox-nix3`
- only after that, planning the dendritic-style widening

## Definition of done

This planning task is done when:

- this plan exists under `docs/plans/`
- the proof-of-migration checkpoint is explicit
- the first implementation pass is limited to `required-baseline`
- validation is centered on `lefant-toolnix`
- widening is explicitly blocked until the checkpoint passes
