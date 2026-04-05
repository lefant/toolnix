# llm-agents cache bootstrap

## Purpose

Recipes that depend on `github:numtide/llm-agents.nix` need a reliable binary-cache prerequisite so fresh machines do not fall back to expensive local source builds. This spec defines the required cache behavior for direct `toolnix` use and for downstream flake recipes that import `toolnix`.

## Requirements

### Direct `toolnix` flake use SHALL publish the llm-agents cache requirement

The `toolnix` flake SHALL publish the Numtide binary cache settings needed by its `llm-agents` input.

**Scenarios:**
- GIVEN a fresh machine using `nix run github:lefant/toolnix#toolnix-pi` WHEN the user accepts the flake configuration THEN Nix uses the Numtide cache instead of rebuilding the `llm-agents` stack from source
- GIVEN a maintainer inspects `toolnix` metadata WHEN they read the repo docs and flake configuration THEN the required cache URL and trusted key are discoverable without consulting external context

### Downstream flake recipes SHALL ensure cache settings before evaluation/build

Any flake recipe that depends on `llm-agents.nix`, whether directly or through `toolnix`, SHALL ensure the required cache settings are configured before heavy evaluation or builds are attempted.

**Scenarios:**
- GIVEN a standalone bootstrap flake that imports `toolnix.homeManagerModules.default` WHEN it is authored for a fresh VM THEN it includes the Numtide cache settings in its own recipe or otherwise ensures the machine already trusts them
- GIVEN a downstream flake recipe omits the cache configuration WHEN it is executed on a fresh VM THEN that recipe is treated as non-compliant with this spec even if the build can eventually complete from source

### Fresh-machine bootstrap guidance SHOULD provide an explicit verification path

The repo SHOULD document a repeatable verification flow for a new VM that proves the cache prerequisite is active before claiming bootstrap success.

**Scenarios:**
- GIVEN a maintainer follows the documented bootstrap proof on a new exe.dev VM WHEN they run the verification commands THEN the logs show cache copies from `cache.numtide.com` and avoid large local build chains
- GIVEN the cache prerequisite is missing or untrusted WHEN the maintainer runs the verification commands THEN the procedure surfaces that failure clearly before the host bootstrap is marked successful

### Untrusted multi-user Nix environments SHALL be handled explicitly

When the active Nix daemon does not allow ordinary users to add arbitrary substituters, the recipe SHALL ensure the Numtide cache is trusted through machine-local Nix configuration before heavy builds begin.

**Scenarios:**
- GIVEN a fresh exe.dev VM with a Determinate multi-user Nix install WHEN a non-root user runs `nix run --accept-flake-config github:lefant/toolnix#toolnix-pi -L` without machine-local trust configured THEN the proof fails fast with an untrusted-substituter signal instead of being treated as success
- GIVEN that same VM WHEN `cache.numtide.com` and its public key are added to trusted machine-local Nix settings first THEN the same proof path uses the cache successfully

## Open Questions

- [ ] Should `toolnix` also document an explicit non-flake `nix.conf` fallback snippet for environments that cannot use `--accept-flake-config`?
- [ ] Should future public bootstrap examples include a helper script that writes a compliant standalone flake automatically?
