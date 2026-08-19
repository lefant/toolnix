# Agent skills show-me bump

Updated Toolnix's pinned `agent-skills` input to revision `42271a01c2fdf08f301726c6f821ae78c33eae83`, which adds the vendored `show-me` skill. Kept `flake.lock` and `devenv.lock` aligned.

## Verification

- Confirmed both lockfiles resolve the same revision and NAR hash.
- Confirmed the Home Manager activation package materializes `show-me` for Pi, Claude, OpenCode, Amp, and the shared agent skill tree.
- `nix flake check --no-build`
- `devenv shell -- true`
- `nix build .#homeConfigurations.lefant-toolnix.activationPackage`

## Rollout

Activated the resulting Home Manager generation locally with `./result/activate` after merging the change.
