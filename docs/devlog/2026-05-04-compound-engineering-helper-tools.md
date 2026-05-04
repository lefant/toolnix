# Compound Engineering helper tools

## Summary

Added a dedicated Compound Engineering helper-tool bundle to Toolnix.

The bundle installs the native tools that Compound Engineering agents prefer and that have good nixpkgs sources:

- `ast-grep`
- `silicon`

`vhs` is intentionally excluded from the default bundle because the nixpkgs package is available but pulls a Chromium-sized closure.

## Changes

- Exposed `toolPackages` from `modules/shared/compound-engineering.nix`.
- Added `toolnix.compoundEngineering.tools.enable`, defaulting to `true` when Compound Engineering is enabled.
- Added Compound Engineering project-shell options for devenv consumers.
- Wired the helper tools into:
  - Home Manager host packages when `toolnix.compoundEngineering.enable && toolnix.compoundEngineering.tools.enable`
  - Toolnix project devenv shells under the same gate
- Added a flake check that validates default helper-tool inclusion, `vhs` exclusion, and `tools.enable = false` opt-out behavior.
- Updated the Compound Engineering spec and plan docs with the helper-tool behavior and opt-out path.

## Validation

- Verified nixpkgs provides sources for:
  - `vhs` 0.11.0
  - `silicon` 0.5.3 package, with binary reporting 0.5.2
  - `ast-grep` 0.42.1
- Verified a one-off Nix shell can run all three tools.
- Ran `nix flake check --no-build` successfully.

## Notes

The local `devenv shell` command did not see uncommitted changes loaded through this repo's `builtins.getFlake` indirection, so the project-shell behavior should be validated again from a clean committed tree or a consumer flake ref.
