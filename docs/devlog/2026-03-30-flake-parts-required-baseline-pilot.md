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

## Scope boundary held

This slice did **not** widen the migration beyond `required-baseline`.

The following remain untouched in this proof slice:

- `opinionated-shell`
- `agent-baseline`
- `agent-browser`
- `host-control`

## Notes

- this proof slice is intended to establish that `flake-parts` and internal auto-import can be introduced without changing current public outputs or breaking the self-hosted `lefant-toolnix` workflow
- a wider migration should only happen after reviewing this checkpoint and planning the next internal layer explicitly
