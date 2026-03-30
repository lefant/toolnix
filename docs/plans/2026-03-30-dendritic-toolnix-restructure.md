# Plan: dendritic-style internal restructuring for toolnix

## Goal

Complete the post-flake-parts internal restructuring of `toolnix` so the repo is organized around feature-oriented flake-parts modules and flake-parts-owned profile composition, while keeping the published interfaces stable.

## Starting point

Already complete before this plan:

- internal `flake-parts` adoption
- internal auto-import scaffold
- flake-parts-owned `homeConfigurations.lefant-toolnix`
- flake-parts-owned `homeManagerModules.default`
- flake-parts-owned `devenvModules.default`
- end-to-end verification on `lefant-toolnix` and `lefant-toolbox-nix{,2,3}` for the proof branch

Current issue:

- the repo still uses a mostly transitional structure
- the main feature slices are not yet first-class flake-parts feature modules
- profile glue still contains too much cross-feature wiring

## Scope

In scope:

- create feature-oriented flake-parts modules for the current A/R/O/H slices
- create profile-oriented flake-parts modules for Home Manager and `devenv`
- keep compatibility wrappers at existing public module paths
- keep public outputs stable
- verify on `lefant-toolnix` and `lefant-toolbox-nix`
- update plan/devlog/reference docs as the refactor lands

Out of scope:

- changing public consumer paths
- wrapper-derivation experiments
- repo-boundary changes involving `hackbox-ctrl` or inventory

## Target architecture

### Feature registry

Feature files should live under a dedicated flake-parts feature tree and publish entries into a merged internal registry.

Initial feature set:

- `required-baseline`
- `agent-baseline`
- `opinionated-shell`
- `agent-browser`
- `host-control`

Each feature should publish the pieces that make sense for that feature, such as:

- raw shared data/helpers
- Home Manager option modules
- Home Manager contribution modules
- `devenv` option modules
- `devenv` contribution modules

### Profile registry

Profile files should live under a dedicated flake-parts profile tree and compose the feature registry into the stable public surfaces.

Initial profile set:

- Home Manager default host profile
- `devenv` default project/self-hosted profile

### Stable public surfaces

These must stay stable:

- `homeConfigurations.lefant-toolnix`
- `homeManagerModules.default`
- `devenvModules.default`
- `devenvSources`
- `modules/home-manager/toolnix-host.nix`
- `modules/devenv/default.nix`
- `modules/devenv/project.nix`

## Implementation sequence

### Step 1 — create dendritic flake-parts registries

- add flake-parts modules that declare mergeable internal registries for:
  - `toolnix.internal`
  - `toolnix.features`
  - `toolnix.profiles`
- export those registries back out through a single `flake.lib.toolnix`
- move public output wiring into flake-parts-owned profile/output modules where practical

### Step 2 — create feature modules for all current A/R/O/H slices

Create one flake-parts feature module per slice:

- `required-baseline`
- `agent-baseline`
- `opinionated-shell`
- `agent-browser`
- `host-control`

Each file should publish the modules/data needed by profiles instead of leaving profiles to wire raw shared imports ad hoc.

### Step 3 — split profile glue into profile modules and profile core files

- create profile modules that assemble Home Manager and `devenv` from the feature registry
- reduce the current compatibility modules to wrappers only
- keep generic non-feature-specific glue in small internal profile core files

### Step 4 — remove transitional one-off structure

- remove now-obsolete transitional flake-parts files once replacements exist
- make the repo shape reflect the new feature/profile split clearly

### Step 5 — verify and document

Verify locally and on:

- `lefant-toolnix`
- `lefant-toolbox-nix`

Minimum checks:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
nix run github:cachix/devenv/latest -- shell -- true
nix run github:cachix/devenv/latest -- shell -- bash -lc 'command -v mg && command -v bat && command -v tmux && command -v just && locale | head -5'
```

On `lefant-toolnix`, also apply the activation result:

```bash
./result/activate
```

## Risks and controls

### Risk: flake-parts registry design causes merge conflicts or evaluation issues

Control:

- use one exporter for `flake.lib.toolnix`
- keep mergeable state under custom internal options first

### Risk: feature slicing changes runtime behavior subtly

Control:

- preserve existing shared helper implementations first
- refactor composition before changing behavior
- verify after each meaningful slice

### Risk: public compatibility paths break

Control:

- keep wrapper modules at existing public paths until the restructuring is complete
- verify `homeManagerModules.default` and `devenvModules.default` continuously

## Definition of done

This plan is done when:

- all current A/R/O/H functionality is published through feature-oriented flake-parts modules
- Home Manager and `devenv` are assembled from flake-parts-owned profile modules
- public paths and outputs remain stable
- verification passes locally, on `lefant-toolnix`, and on `lefant-toolbox-nix`
- the repo is ready for future optional work such as wrapped-tool exports without needing another structural reset
