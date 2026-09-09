# Amp orb development setup

## Goal

Make a fresh Amp orb able to evaluate, build, and test the locked Toolnix Nix stack without manual machine preparation.

## Plan

1. Add an idempotent `.agents/setup` that installs Nix, configures Toolnix's required Numtide cache, installs `devenv`, and evaluates the flake.
2. Verify setup from the current fresh orb, repeat it to prove the warm path, and run the repository's build and shell smoke tests.
3. Document how normal pinned `agent-skills` consumption differs from an explicit local checkout override used for cross-repository development.
4. Record the result and any remaining operational caveats in a devlog.

## Acceptance checks

```bash
.agents/setup
.agents/setup
nix --accept-flake-config flake check --no-build --no-eval-cache
nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage --no-link
devenv shell -- true
```
