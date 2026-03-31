## Summary

Updated the locked `llm-agents` flake input to pick up newer tracked agent tool versions without changing the repo's source modules or templates.

## What changed

Changed:

- `flake.lock`

Updated `llm-agents`:

- `4814adf48100a2138b02591e6a7e000c106887b1`
- -> `fb1dfb5960aa4b8a91995f8f99ec2452e5052dbe`

This also advanced the transitive `llm-agents/nixpkgs` lock entry.

## Verified versions

After the lock update, the repo now exposes:

- `claude-code`: `2.1.88`
- `codex`: `0.117.0`
- `pi`: `0.64.0`
- `beads`: `0.62.0`
- `opencode`: `1.3.9`
- `amp`: `0.0.1774923411-g30ee34`

## Why

This was the highest-value tool update available in the repo because `toolnix` sources its tracked agent CLIs from `llm-agents`, so one lock bump updates the full bundled agent set used by the agent baseline.

## Notes

- baseline tools from locked `nixpkgs` were already current relative to `cachix/devenv-nixpkgs/rolling`
- `claude-code-plugins` and `flake-parts` were already up to date at review time
- unrelated worktree changes were left untouched and excluded from this landing commit
