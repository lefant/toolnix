## Summary

Refreshed Toolnix's Nix/devenv software inputs to current upstream revisions, repaired the Compound Engineering integration for the updated upstream plugin layout, and moved tracked agent defaults to GPT-5.6 Sol high-reasoning defaults.

## What changed

Changed:

- `flake.lock`
- `devenv.lock`
- `agents/pi-coding-agent/templates/settings.json`
- `agents/codex/templates/config.toml`
- `agents/opencode/templates/opencode.json`
- `modules/shared/compound-engineering.nix`
- `modules/shared/compound-engineering/render-pi-assets.py`
- `modules/shared/compound-engineering/render-opencode-assets.py`
- `modules/shared/compound-engineering/render-codex-assets.py`
- `flake-parts/features/compound-engineering.nix`
- `docs/reference/pi-model-backends.md`

Updated agent versions now observed locally:

- `claude-code`: `2.1.233`
- `codex`: `0.147.0`
- `pi`: `0.84.2`
- `opencode`: `1.18.18`
- `amp`: `0.0.1786924891-g5a5391`
- `bd` / beads: `1.2.2`
- `agent-browser`: `0.34.0`

Tracked model defaults now use:

- Pi: `openai-codex` / `gpt-5.6-sol` / `high`
- Codex: `gpt-5.6-sol` / `high`
- OpenCode: `openai/gpt-5.6-sol`, small model `openai/gpt-5.6-luna-fast`, `reasoningEffort = high`

## Notes

The updated `compound-engineering-plugin` no longer has the old `plugins/compound-engineering/{skills,agents}` layout. Toolnix now detects the repository-root layout, discovers agents from `skills/*/references/agents`, and keeps rendering Pi, OpenCode, Codex, and Claude-compatible assets.

The updated Pi package exposes GPT-5.6 Sol/Terra/Luna through both `openai` and `openai-codex`; `openai-codex/gpt-5.6-sol` was verified available and auth-ready on this host.

## Verification

Verified with:

```bash
nix flake update --accept-flake-config
devenv update
nix flake check --accept-flake-config
nix build --accept-flake-config .#homeConfigurations.lefant-toolnix.activationPackage
nix run --accept-flake-config .#toolnix-pi -- --version
devenv shell -- true
./result/activate
pi --version
codex --version
opencode --version
claude --version
bd --version
amp --version
jq '{defaultProvider,defaultModel,defaultThinkingLevel}' ~/.pi/agent/settings.json
rg -n '^(model|model_reasoning_effort) =' ~/.codex/config.toml
jq '{model,small_model,reasoningEffort:.provider.openai.options.reasoningEffort}' ~/.config/opencode/opencode.json
pi --list-models gpt-5.6
pi auth check --provider openai-codex --model gpt-5.6-sol
opencode models openai | rg 'gpt-5\.6'
```

Observed:

- Home Manager build succeeded.
- Home Manager activation succeeded locally.
- `devenv shell -- true` succeeded.
- Pi reports `0.84.2` and lists `openai-codex/gpt-5.6-sol` with thinking support.
- `pi auth check --provider openai-codex --model gpt-5.6-sol` returned `ready`.
- OpenCode lists `openai/gpt-5.6-sol`, `openai/gpt-5.6-terra`, and `openai/gpt-5.6-luna` variants.
