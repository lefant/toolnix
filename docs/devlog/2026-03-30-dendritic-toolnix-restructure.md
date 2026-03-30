## Summary

Completed the dendritic-style internal restructuring of `toolnix` after the flake-parts migration checkpoint.

The repo now organizes its internals around:

- merged flake-parts feature registries
- merged flake-parts profile registries
- stable public wrappers at the existing module paths

## What changed

### Flake-parts registries

Added flake-parts modules for merged internal registries:

- `flake-parts/toolnix-options.nix`
- `flake-parts/export-toolnix-lib.nix`
- `flake-parts/public-outputs.nix`

`flake.lib.toolnix` is now exported from a single dedicated flake-parts module and contains:

- `internal`
- `features`
- `profiles`

### Feature modules

Added a dedicated feature tree:

- `flake-parts/features/required-baseline.nix`
- `flake-parts/features/agent-baseline.nix`
- `flake-parts/features/opinionated-shell.nix`
- `flake-parts/features/agent-browser.nix`
- `flake-parts/features/host-control.nix`

These modules now publish the current A/R/O/H slices into the merged flake-parts feature registry.

### Profile modules

Added a dedicated profile tree:

- `flake-parts/profiles/home-manager.nix`
- `flake-parts/profiles/devenv.nix`

Added profile core files:

- `internal/profiles/home-manager/core.nix`
- `internal/profiles/devenv/core.nix`

These profiles assemble the public Home Manager and `devenv` surfaces from the feature registry.

### Transitional cleanup

Removed the earlier transitional files that were only needed for the flake-parts proof checkpoint:

- `flake-parts/required-baseline.nix`
- `internal/home-manager/toolnix-host-base.nix`
- `internal/devenv/default-base.nix`

`flake.nix` is now thinner and delegates internal structure entirely to flake-parts imports.

## Compatibility that stayed stable

These public surfaces remained stable:

- `homeConfigurations.lefant-toolnix`
- `homeManagerModules.default`
- `devenvModules.default`
- `devenvSources`
- `modules/home-manager/toolnix-host.nix`
- `modules/devenv/default.nix`
- `modules/devenv/project.nix`

The compatibility modules continue to forward to the flake-parts-owned exported profiles.

## Local validation

Validated with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
nix run github:cachix/devenv/latest -- shell -- true
nix run github:cachix/devenv/latest -- shell -- bash -lc 'command -v mg && command -v bat && command -v tmux && command -v just && locale | head -5'
```

Observed:

- Home Manager activation package still builds
- `devenv` shell still enters successfully
- baseline tools remain present
- locale behavior remains stable

## Remote verification

Rolled out and verified on:

- `lefant-toolnix`
- `lefant-toolbox-nix`

Commands used:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate   # on lefant-toolnix only
nix run github:cachix/devenv/latest -- shell -- true
nix run github:cachix/devenv/latest -- shell -- bash -lc 'command -v mg && command -v bat && command -v tmux && command -v just && locale | head -5'
```

Observed remotely:

- Home Manager activation still builds on both hosts
- Home Manager activation still applies cleanly on `lefant-toolnix`
- `devenv` shell entry remains stable
- baseline tools remain present
- locale behavior remains stable

## Notes

- this completes the intended dendritic-style internal restructuring for the current `toolnix` feature set without changing the published consumer interface
- the next sensible work should be additive rather than another structural reset, for example selected wrapped-tool exports or ordinary feature work on top of the new structure
