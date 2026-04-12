## Summary

Updated the locked `llm-agents` flake input so `toolnix` picks up the newest tracked `claude-code`, `codex`, and `pi` releases currently published by `github:numtide/llm-agents.nix`.

## What changed

Changed:

- `flake.lock`
- `docs/devlog/2026-04-12-llm-agents-bump.md`

Updated `llm-agents`:

- `c9e352e53c5164b68dd05acf5a87d5798b6aa003`
- -> `e20e7ebdbf8b4d342bd343a630af8e900a55a48a`

This also advanced the transitive lock entries for:

- `llm-agents/nixpkgs`
- `llm-agents/treefmt-nix`

## Verified versions

After the lock update, the repo resolves these tracked agent tool versions:

- `claude-code`: `2.1.104`
- `codex`: `0.120.0`
- `pi`: `0.66.1`
- `beads`: `1.0.0`
- `opencode`: `1.4.3`
- `amp`: `0.0.1775995534-g3f79eb`

## Verification

Verified with:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux."claude-code".version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.codex.version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.pi.version'

nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

The Home Manager build fetched the updated agent binaries from `https://cache.numtide.com`, including:

- `claude-code-2.1.104`
- `codex-0.120.0`
- `pi-0.66.1`

## Why

`toolnix` sources its tracked agent CLIs from `llm-agents`, so this lock bump is the canonical repo-local way to keep the bundled agent baseline current without changing the module wiring.

## Notes

- no source module changes were required
- the existing `modules/shared/agent-baseline.nix` wiring already picks these tools up from the locked `llm-agents` input
- unrelated untracked working-tree files were left untouched during this maintenance pass
