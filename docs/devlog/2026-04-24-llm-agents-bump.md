## Summary

Bumped `toolnix` to the latest `github:numtide/llm-agents.nix` revision so the tracked agent CLI set moves forward again.

The updated lock now resolves these agent versions:

- `claude-code`: `2.1.119`
- `codex`: `0.124.0`
- `pi`: `0.70.0`
- `opencode`: `1.14.22`
- `amp`: `0.0.1777006714-g2207a5`
- `beads`: `1.0.2`

## What changed

Changed:

- `flake.lock`
- `devenv.lock`
- `docs/devlog/2026-04-24-llm-agents-bump.md`

Updated `llm-agents`:

- `92de4ace99ea70a24146f7c2b71ff65e4ce358a8`
- -> `8ff0f2a7fcd176b4547da6879ad549de2bbded41`

Aligned the same `llm-agents` revision in `devenv.lock`.

This upstream bump also changed the transitive `bun2nix` input used by `llm-agents`:

- `Mic92/bun2nix` `catalog-support` `648d293c51e981aec9cb07ba4268bc19e7a8c575`
- -> `nix-community/bun2nix` `staging-2.1.0` `6ef9f144616eedea90b364bb408ef2e1de7b310a`

## Verification

Verified with:

```bash
nix flake update llm-agents
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
nix run .#toolnix-pi -- --version
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux."claude-code".version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.codex.version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.pi.version'
```

The Home Manager build and wrapped `pi` path fetched the updated agent binaries from `https://cache.numtide.com`.

## Notes

`toolnix` keeps both `flake.lock` and `devenv.lock`, so the bump needed to stay aligned across both lockfiles.
