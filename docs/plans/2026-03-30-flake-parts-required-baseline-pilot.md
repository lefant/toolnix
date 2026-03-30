# Plan: introduce flake-parts and internal auto-import in toolnix, piloting on required-baseline first

## Goal

Introduce `flake-parts` inside `toolnix` as an internal structuring mechanism while keeping current public outputs stable.

The migration should start with a narrow proof-of-migration on `modules/shared/required-baseline.nix`, validate that the self-hosted `lefant-toolnix` workflow still behaves the same, and only widen after that checkpoint passes.

## Scope

In scope:

- internal `flake-parts` adoption inside `toolnix`
- internal auto-import for flake-parts modules
- a first pilot migration of `required-baseline`
- preservation of existing public flake outputs and import paths
- validation on the self-hosted `lefant-toolnix` workflow

Out of scope for this plan:

- redesigning published consumer interfaces
- optimizing for downstream consumer hosts
- control-host or inventory workflow changes
- broad migration of all shared modules in the first pass

## Current state

Today `toolnix` still uses a hand-written `flake.nix` with explicit `outputs = inputs@{ ... }:` wiring.

Key properties of the current design:

- `homeConfigurations.lefant-toolnix` is built directly in `flake.nix`
- `homeManagerModules.default` exports `modules/home-manager/toolnix-host.nix`
- `devenvSources` is assembled manually in `flake.nix`
- `devenvModules.default` wraps `modules/devenv/default.nix` and injects a merged `inputs` set
- shared internal layering is file-based under `modules/shared/`

The self-hosted workflow depends on these public outputs staying stable:

- `nix build .#homeConfigurations.lefant-toolnix.activationPackage`
- `devenv shell`
- path-based imports such as `modules/devenv/project.nix`

## Desired end state

`toolnix` should use `flake-parts` internally to organize flake outputs and internal components, while preserving the current external interface.

That means:

- callers should still see the same top-level public outputs
- existing module import paths should remain valid during the migration
- `flake-parts` should improve internal composition, not force a public interface break
- internal auto-import should remove manual module registration drift for the new flake-parts layer

## Migration principles

1. Keep public outputs stable first.
2. Migrate one internal layer at a time.
3. Start with the smallest low-risk shared module: `required-baseline`.
4. Validate on `lefant-toolnix` before widening.
5. Do not widen the migration until the proof checkpoint passes.

## Proposed internal architecture

### 1. Add flake-parts as an internal composition layer

Introduce `flake-parts` as a flake input and move top-level output construction into a `mkFlake` structure.

The first migration should preserve these public outputs exactly:

- `homeConfigurations.lefant-toolnix`
- `homeManagerModules.default`
- `devenvSources`
- `devenvModules.default`

The first implementation should prefer compatibility wrappers over structural cleverness.

### 2. Add an internal auto-import mechanism for flake-parts modules

Add a small internal loader for flake-parts modules, for example under a path like:

- `flake-parts/`
- or `internal/flake/`

The loader should:

- auto-import `.nix` files from a dedicated internal flake-parts directory
- stay internal-only
- avoid changing the existing public module file layout under `modules/`

The auto-import mechanism should be introduced for flake-parts organization only, not for all repo modules at once.

### 3. Pilot on required-baseline first

The first migrated internal unit should be `modules/shared/required-baseline.nix`.

Reasoning:

- it is small
- it has no complex dynamic shell logic
- it is used by both host and project paths
- it offers a good proof that flake-parts wiring can preserve current behavior without touching more volatile layers yet

The pilot should convert only the ownership/wiring of `required-baseline`, not the whole shared module tree.

## Proof-of-migration checkpoint

This checkpoint must be explicit and blocking.

Do not widen the migration beyond `required-baseline` until all checkpoint items pass.

### Checkpoint objective

Prove that `flake-parts` plus internal auto-import can be introduced without changing current public outputs or breaking the self-hosted `lefant-toolnix` workflow.

### Checkpoint implementation scope

At the checkpoint, the repo should have:

- `flake-parts` added
- internal flake-parts auto-import in place
- only `required-baseline` piloted through the new internal path
- all other internal layers still effectively behaving as before

### Checkpoint validation

The checkpoint passes only if all of the following hold:

#### Public output stability

- `homeConfigurations.lefant-toolnix` still exists and builds
- `homeManagerModules.default` still resolves as before
- `devenvSources` still exposes the same expected inputs
- `devenvModules.default` still works for the self-hosted shell path

#### Self-hosted workflow validation on `lefant-toolnix`

- `nix build .#homeConfigurations.lefant-toolnix.activationPackage`
- `devenv shell -- true`
- interactive smoke check that the shell still contains the expected baseline commands from `required-baseline`
  - `mg`
  - `bat`
  - `tmux`
  - `just`
  - plus host/project-specific expectations for `git` and `gh` where they already apply

#### No public-path churn

- no change to published paths like `modules/devenv/project.nix`
- no change to consumer-facing import examples in `README.md` unless they are purely clarifying

## Implementation steps

### Step 1 — Add planning and migration guardrails

- create this plan document
- document the explicit proof-of-migration checkpoint
- define the stability requirements for public outputs and self-hosted verification

### Step 2 — Introduce flake-parts without changing public outputs

- add `flake-parts` as a flake input
- convert `flake.nix` to `flake-parts.lib.mkFlake`
- preserve the same top-level public outputs by re-expressing current logic inside flake-parts
- keep naming and output structure unchanged

Notes for this step:

- prefer a thin flake-parts shell around the existing output logic
- do not mix in unrelated cleanups
- do not move public modules yet

### Step 3 — Add internal auto-import for flake-parts modules

- create a dedicated internal directory for flake-parts modules
- add a small helper that auto-imports those internal modules
- keep the mechanism scoped to flake-parts internals only
- avoid changing current `modules/` file discovery or public module paths

Notes for this step:

- the auto-import convention should be simple and predictable
- one file per internal flake-parts concern is enough to start
- filename-driven import is acceptable
- nested recursive discovery is optional, but a flat initial directory is preferred for the pilot

### Step 4 — Pilot required-baseline through the new internal path

- create the first flake-parts-backed internal representation or wiring for `required-baseline`
- keep `modules/shared/required-baseline.nix` stable at the call-site level unless a compatibility wrapper is clearly better
- route the internal flake-parts composition through the new structure for this one baseline only
- ensure both host and project paths still receive the same effective package and environment values

Notes for this step:

- do not bundle additional shared modules into the pilot
- do not migrate `opinionated-shell`, `agent-baseline`, `agent-browser`, or `host-control` until the proof checkpoint has passed

### Step 5 — Run the proof-of-migration checkpoint

Run at least:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

Then run an interactive self-hosted smoke check on `lefant-toolnix` to confirm required-baseline tools are still present where expected.

Capture exactly what stayed stable:

- output names
- build commands
- shell entry
- baseline tool availability

### Step 6 — Record the checkpoint result before widening

If the checkpoint passes:

- write a devlog describing the proof result and any compatibility constraints discovered
- update architecture or reference docs only as needed to reflect the internal flake-parts adoption
- create a follow-on plan for the next internal layer or layers

If the checkpoint fails:

- stop the migration there
- document the incompatibility or interface drift
- revert or narrow the internal change until public outputs and self-hosted behavior match expectations again
