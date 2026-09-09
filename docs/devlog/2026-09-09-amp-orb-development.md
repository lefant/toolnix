# Amp orb development setup

## Outcome

Added a repository-owned Amp orb bootstrap for Toolnix. Fresh orbs now install Determinate Nix, configure the machine-level Numtide cache trust required by `llm-agents.nix`, install the cached `devenv` CLI, build the Home Manager activation package, and evaluate all flake outputs.

The setup also makes Nix available to later non-interactive login shells. Amp's base `~/.env` resets `PATH` after `/etc/profile.d/nix.sh` runs, so the repository hook deliberately reloads the Nix profile after that reset.

The repository's `devenv-nixpkgs` input uses import-from-derivation. On an empty store, `flake check --no-build` cannot materialize that patched source and reports its `.drv` as invalid. Setup therefore performs the real Home Manager build before the no-build evaluation pass.

## agent-skills integration

Toolnix already consumes `github:lefant/agent-skills` as a pinned non-flake input in both lockfiles. For cross-repository Amp work, add `agent-skills` as an additional repository on the Toolnix project. Amp then checks it out beside Toolnix and shows both diffs in one thread.

Pinned builds remain reproducible. Work-in-progress skill changes are tested explicitly with:

```bash
nix --accept-flake-config build \
  .#homeConfigurations.lefant-toolnix.activationPackage \
  --override-input agent-skills path:../agent-skills \
  --no-link
```

## Verification

- The final `.agents/setup` completed in 24.42 seconds, then in 11.86 seconds on the repeated warm path.
- `nix build .#homeConfigurations.lefant-toolnix.activationPackage --no-link` completed successfully from the fresh orb.
- `nix flake check --no-build --no-eval-cache` evaluated all checks successfully after the build materialized the patched nixpkgs source.
- `devenv shell -- true` completed successfully.
- A clean `bash -lc` found Nix and devenv from their persistent paths.
- The Home Manager build succeeded with a temporary adjacent checkout of current `agent-skills` main passed through `--override-input`.

Nix still prints expected restricted-setting warnings when the flake repeats `trusted-public-keys` as a client option. The same key and substituter are active at the machine level, and build output confirmed downloads from `cache.numtide.com`.
