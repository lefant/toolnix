## Summary

Checked upstream `llm-agents` again, bumped the pinned input to the latest revision, and moved the tracked `pi`, `codex`, and `opencode` defaults to `gpt-5.5`.

The updated lock now resolves these agent versions:

- `claude-code`: `2.1.120`
- `codex`: `0.124.0`
- `pi`: `0.70.2`
- `opencode`: `1.14.24`
- `amp`: `0.0.1777092396-g58772b`
- `beads`: `1.0.3`

## What changed

Changed:

- `flake.lock`
- `devenv.lock`
- `agents/pi-coding-agent/templates/settings.json`
- `agents/codex/templates/config.toml`
- `agents/opencode/templates/opencode.json`
- `docs/devlog/2026-04-25-llm-agents-pi-bump-and-gpt-5.5-defaults.md`

Updated `llm-agents`:

- `8ff0f2a7fcd176b4547da6879ad549de2bbded41`
- -> `6b4673fddbbe1f2656b3fa8d2a32666570aafbfa`

Confirmed the upstream version delta relevant to this pass:

- `pi`: `0.70.0` -> `0.70.2`
- `codex`: unchanged at `0.124.0`

Moved tracked defaults:

- `pi` `defaultModel`: `gpt-5.4` -> `gpt-5.5`
- `codex` `model`: `gpt-5.4` -> `gpt-5.5`
- `opencode` `model`: `openai/gpt-5.4` -> `openai/gpt-5.5`
- `opencode` `small_model`: `openai/gpt-5.4-mini` -> `openai/gpt-5.5-mini`

## Why

The upstream `llm-agents` input had advanced beyond the repo lock, and `toolnix` sources its tracked agent CLI set from that input.

Separately, the repo-level default model target for the managed `pi`, `codex`, and `opencode` paths needed to move forward to `gpt-5.5` while keeping the existing high-reasoning posture where configured.

## Verification

Verified with:

```bash
git ls-remote https://github.com/numtide/llm-agents.nix.git HEAD
nix flake lock --update-input llm-agents
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
jq . agents/opencode/templates/opencode.json
nix run .#toolnix-pi -- --version
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux."claude-code".version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.codex.version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.pi.version'
```

Observed results:

- `toolnix-pi -- --version` => `0.70.2`
- `codex` => `0.124.0`
- `pi` => `0.70.2`
- Home Manager build succeeded
- `devenv shell -- true` succeeded
- `agents/opencode/templates/opencode.json` parsed successfully with `jq`

## Notes

`toolnix` keeps both `flake.lock` and `devenv.lock`, so the `llm-agents` bump needed to stay aligned across both lockfiles.

The `pi`, `codex`, and `opencode` default-model changes are template changes. In this repo's managed Home Manager path they are force-linked, so they apply on the next activation. The wrapped `toolnix-pi` path also picks up the updated `pi` template automatically.
