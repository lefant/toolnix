## Summary

Completed the first proof-of-migration slice for the flake-parts plan on branch `flake-parts-required-baseline-pilot`.

This slice introduced `flake-parts` conservatively inside `toolnix`, added a small internal auto-import scaffold for flake-part modules, and piloted only the `required-baseline` wiring through the new internal path.

## What Changed

### Flake-parts scaffold

`flake.nix` now uses `flake-parts.lib.mkFlake` while preserving the existing public outputs:

- `homeConfigurations.lefant-toolnix`
- `homeManagerModules.default`
- `devenvSources`
- `devenvModules.default`

Added internal flake-parts scaffolding:

- `flake-parts/auto-import.nix`
- `flake-parts/default.nix`
- `flake-parts/required-baseline.nix`

The auto-import mechanism is intentionally scoped only to the internal flake-parts directory.

### Required-baseline pilot

Moved the required-baseline source of truth to:

- `internal/shared/required-baseline.nix`

Kept the existing module path stable by changing:

- `modules/shared/required-baseline.nix`

into a compatibility wrapper that imports the internal implementation.

The flake-parts side points at the same internal source so the pilot actually exercises the new internal path.

## Validation

Validated with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
devenv shell -- bash -lc 'command -v mg && command -v bat && command -v tmux && command -v just && locale | head -5'
```

Observed:

- Home Manager activation package still builds
- self-hosted `devenv` shell still enters successfully
- `mg`, `bat`, `tmux`, and `just` remain available
- locale output still reflects the `required-baseline` env values

## Full flake-parts proof checkpoint

A second implementation slice completed the actual flake-parts-owned consumer proof for the Home Manager path.

### What changed in the proof completion slice

Added:

- `internal/home-manager/toolnix-host-base.nix`

Changed:

- `flake.nix`
- `flake-parts/required-baseline.nix`
- `modules/home-manager/toolnix-host.nix`

The Home Manager path is now composed this way:

- `flake-parts/required-baseline.nix` publishes a flake-parts-owned Home Manager profile module under `self.lib.toolnix.profiles.homeManager.defaultModule`
- `flake.nix` builds `homeConfigurations.lefant-toolnix` from that flake-parts-owned module
- `homeManagerModules.default` now exports that same flake-parts-owned module
- `modules/home-manager/toolnix-host.nix` is reduced to a compatibility wrapper that forwards to `toolnixFlake.homeManagerModules.default`

That means `required-baseline` is no longer only sharing source-of-truth data with flake-parts; one real consumer path is now actually assembled through flake-parts-owned composition.

### Validation after the proof completion slice

Validated locally with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
nix run github:cachix/devenv/latest -- shell -- true
nix run github:cachix/devenv/latest -- shell -- bash -lc 'command -v mg && command -v bat && command -v tmux && command -v just && locale | head -5'
```

Observed:

- `homeConfigurations.lefant-toolnix` still builds after the profile composition moved behind flake-parts
- `homeManagerModules.default` still resolves
- the self-hosted `devenv` shell still enters successfully
- baseline tools and locale values remain stable in the shell

## Scope boundary held

This proof still did **not** widen the migration beyond `required-baseline`.

The following remain untouched as flake-parts feature slices:

- `opinionated-shell`
- `agent-baseline`
- `agent-browser`
- `host-control`

## Full flake-parts functional coverage

A third implementation slice extended the migration from the initial Home Manager proof to the remaining top-level functional surface.

### What changed in the full-coverage slice

Added:

- `internal/devenv/default-base.nix`

Changed:

- `flake.nix`
- `flake-parts/required-baseline.nix`
- `modules/devenv/default.nix`

The `devenv` path is now composed this way:

- `flake-parts/required-baseline.nix` publishes `self.lib.toolnix.profiles.devenv.defaultModule`
- `flake.nix` exports `devenvModules.default` from that flake-parts-owned profile module
- `modules/devenv/default.nix` is reduced to a compatibility wrapper that forwards to `toolnixFlake.devenvModules.default`
- `modules/devenv/project.nix` remains stable and continues to import `./default.nix`

At this point both public runtime entry surfaces are flake-parts-owned:

- Home Manager host profile export/build path
- `devenv` module export path

### Validation after the full-coverage slice

Validated locally with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
nix run github:cachix/devenv/latest -- shell -- true
nix run github:cachix/devenv/latest -- shell -- bash -lc 'command -v mg && command -v bat && command -v tmux && command -v just && locale | head -5'
```

Observed:

- `homeConfigurations.lefant-toolnix` still builds
- `homeManagerModules.default` still resolves
- `devenvModules.default` still resolves and works through the compatibility path
- baseline shell behavior remains stable

## Notes

- the repo now has full flake-parts coverage for the current public functional surfaces: `homeConfigurations`, `homeManagerModules.default`, `devenvModules.default`, and `devenvSources`
- the remaining step after rollout verification is not more top-level flake migration, but deciding whether and how to widen into dendritic-style per-feature modules
