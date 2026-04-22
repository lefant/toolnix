# Pi model backends in toolnix

This document describes the current local-only pattern for adding experimental `pi` model backends on a self-hosted `toolnix` machine.

At the moment, the validated local patterns are:

- custom Together models via `~/.pi/agent/models.json`
- built-in Fireworks models selected directly through pi's `fireworks` provider

See also:

- [`architecture.md`](architecture.md)
- [`credentials.md`](credentials.md)
- [`maintaining-toolnix.md`](maintaining-toolnix.md)
- [`../research/2026-04-09-experimental-pi-model-backend-qwen3-coder-next.md`](../research/2026-04-09-experimental-pi-model-backend-qwen3-coder-next.md)

## Scope

This is about host-local `pi` model configuration under `~/.pi/agent/`.

It is intentionally:

- local to a machine/user account
- opt-in at runtime
- outside the tracked repo state

It is **not** currently a repo-managed Home Manager artifact.

## Current local setup shape

The current experimental `pi` backend setup uses two patterns.

### 1. Custom Together provider

This path uses:

- `~/.pi/agent/models.json`
- a local helper script at `~/.pi/agent/bin/together-api-key.sh`
- `TOGETHER_AI_API_KEY` in `~/.env.toolnix`

The helper script exists so `pi` can resolve the Together API key even when the shell has not exported the variable explicitly.

### 2. Built-in Fireworks provider

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
