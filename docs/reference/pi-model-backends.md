# Pi model backends in toolnix

This document describes Toolnix's tracked Pi default and local-only experimental model backends.

At the moment, the validated local patterns are:

- built-in OpenAI Codex GPT-6 Astra selected through pi's `openai-codex` provider
- custom Together models via `~/.pi/agent/models.json`
- built-in Fireworks models selected directly through pi's `fireworks` provider

See also:

- [`architecture.md`](architecture.md)
- [`credentials.md`](credentials.md)
- [`maintaining-toolnix.md`](maintaining-toolnix.md)
- [`../research/2026-04-09-experimental-pi-model-backend-qwen3-coder-next.md`](../research/2026-04-09-experimental-pi-model-backend-qwen3-coder-next.md)

## Scope

Home Manager manages the default provider, model, and thinking level in `~/.pi/agent/settings.json` from `agents/pi-coding-agent/templates/settings.json`.

Experimental providers in `~/.pi/agent/models.json` and all credentials remain machine-local, opt-in state. Home Manager does not manage those files.

## Current local setup shape

The current experimental `pi` backend setup uses three patterns.

### 1. Built-in OpenAI Codex provider

The tracked `pi` template now defaults to:

- provider: `openai-codex`
- model: `gpt-6-astra`
- thinking level: `high`

Pi 0.85.0 exposes `gpt-6-astra` through `openai-codex` with thinking support and a 272K context window. An Astra/high smoke test passed on 2026-09-05.

Codex and OpenCode also default to Astra with high effort. OpenCode 1.18.29 lists `openai/gpt-6-astra`; 1.18.18 did not, even after a catalog refresh. OpenCode's small model remains `openai/gpt-5.6-luna-fast`. Local OAuth refresh failures blocked Codex and OpenCode inference checks on 2026-09-05; catalog/configuration checks are not proof of account access.

### Default rollout and overrides

- Build and activate Home Manager to update persistent host defaults. See [maintaining-toolnix.md](maintaining-toolnix.md).
- Start a new session to use the new defaults. Resumed sessions, explicit CLI selections, and project settings can retain another model or effort level.
- Pi 0.85.0 also supports `modelThinkingLevels` overrides per provider/model. The tracked template does not set these.
- Wrapped `toolnix-pi` seeds settings only when the target is missing or a broken symlink. Existing settings, including valid links to older store paths, are preserved. Use `--provider openai-codex --model gpt-6-astra --thinking high` for a one-run override, or inspect and deliberately update the wrapper's settings.
- The wrapper's default settings path is `${XDG_STATE_HOME:-$HOME/.local/state}/toolnix/pi/agent/settings.json`; `TOOLNIX_WRAPPED_STATE_DIR` or `PI_CODING_AGENT_DIR` can change it.
- Devenv supplies packages and shell-local defaults; it does not rewrite persistent agent settings.

Pi's compaction settings remain unchanged: enabled, 100,000 reserved tokens, and 20,000 recent tokens retained. The reserve causes proactive compaction around 172K tokens with this 272K model window; it is not an output-token limit.

### 2. Custom Together provider

This path uses:

- `~/.pi/agent/models.json`
- a local helper script at `~/.pi/agent/bin/together-api-key.sh`
- `TOGETHER_AI_API_KEY` in `~/.env.toolnix`

The helper script exists so `pi` can resolve the Together API key even when the shell has not exported the variable explicitly.

### 3. Built-in Fireworks provider

This path uses:

- pi's built-in `fireworks` provider
- `FIREWORKS_API_KEY` in `~/.env.toolnix`

This does not currently require a custom `models.json` provider entry when the desired Fireworks serverless model is already known to pi.

## Current validated models

### Together custom models

The current local Together provider is configured with these model IDs:

- `Qwen/Qwen3-Coder-Next-FP8`
- `moonshotai/Kimi-K2.5`

Current intended usage:

- use `Qwen/Qwen3-Coder-Next-FP8` as the simpler coding-focused experimental path
- use `moonshotai/Kimi-K2.5` when you want Together-backed Kimi with reasoning enabled

### Fireworks built-in models

The current self-hosted Fireworks proof worked with these built-in pi model IDs:

- `accounts/fireworks/models/kimi-k2p5`
- `accounts/fireworks/models/qwen3-8b`

Current intended usage:

- use `accounts/fireworks/models/kimi-k2p5` when you want Fireworks-backed Kimi with reasoning support
- use `accounts/fireworks/models/qwen3-8b` as a lightweight Fireworks-backed Qwen serverless option

## Opt-in rule

These custom Together and Fireworks model paths are opt-in.

Normal `pi` use is unchanged unless you explicitly select the provider/model you want.

That means the standard path remains:

```bash
pi
```

To opt into one of these backends for a session, launch `pi` with explicit provider/model arguments.

## How to switch to the validated models

### OpenAI Codex GPT-6 Astra

```bash
pi --provider openai-codex --model gpt-6-astra --thinking high
```

### Together Qwen3-Coder-Next

```bash
pi --provider together --model Qwen/Qwen3-Coder-Next-FP8
```

### Together Kimi K2.5

```bash
pi --provider together --model moonshotai/Kimi-K2.5
```

### Fireworks Kimi

```bash
pi --provider fireworks --model accounts/fireworks/models/kimi-k2p5
```

### Fireworks Qwen

```bash
pi --provider fireworks --model accounts/fireworks/models/qwen3-8b
```

### Interactive model picker

You can also start `pi` normally and switch interactively:

```text
/model
```

Then choose the Together or Fireworks provider entry you want.

## Batch-mode examples

### Together Qwen

```bash
pi --provider together --model Qwen/Qwen3-Coder-Next-FP8 --thinking off -p "Summarize this repo"
```

### Together Kimi

```bash
pi --provider together --model moonshotai/Kimi-K2.5 --thinking high -p "Which number is bigger, 9.11 or 9.9?"
```

### Fireworks Kimi

```bash
pi --provider fireworks --model accounts/fireworks/models/kimi-k2p5 --thinking high -p "Summarize this repo"
```

### Fireworks Qwen

```bash
pi --provider fireworks --model accounts/fireworks/models/qwen3-8b --thinking off -p "Reply with OK only"
```

## Credential source

The expected local secret path is still:

- `~/.env.toolnix`

Current examples:

```bash
TOGETHER_AI_API_KEY=...
FIREWORKS_API_KEY=...
```

As with other local runtime secrets in `toolnix`, these values are machine-local and must not be committed to the repo.

## Ownership boundary

Current ownership is:

- `toolnix` docs may describe the pattern
- the actual live `~/.pi/agent/models.json` and helper script remain host-local mutable state
- Together and Fireworks API keys remain local secret state in `~/.env.toolnix`

If this setup becomes something `toolnix` should publish declaratively for hosts, that should be treated as a separate architecture change.
