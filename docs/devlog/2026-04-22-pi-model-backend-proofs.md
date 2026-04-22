---
date: 2026-04-22
status: ✅ COMPLETED
related_research: docs/research/2026-04-09-experimental-pi-model-backend-qwen3-coder-next.md
related_issues: []
---

# Implementation Log - 2026-04-22

**Implementation**: Documented host-local `pi` model backend usage for Together and Fireworks, then proved both provider paths against live serverless models in the self-hosted tmux workflow.

## Summary

This session turned an earlier Together-only research spike into a clearer maintainer reference for local `pi` model backends in `toolnix`. The docs now explain the host-local ownership boundary, opt-in model switching flow, and current credential expectations for both custom Together models and built-in Fireworks models. On the host itself, the session also validated live serverless `pi` usage against Together and Fireworks, including Fireworks Kimi and Fireworks Qwen, using tmux proof windows inside the normal `tmux-here` workflow.

## Plan vs Reality

**What was planned:**
- [ ] Capture the local `pi` model backend pattern in repo reference docs
- [ ] Keep the setup explicitly opt-in and machine-local
- [ ] Verify at least one experimental provider path in real usage
- [ ] Record the outcome in a devlog

**What was actually implemented:**
- [x] Added `docs/reference/pi-model-backends.md`
- [x] Linked the new reference doc from `README.md`, `docs/reference/credentials.md`, and `docs/reference/maintaining-toolnix.md`
- [x] Expanded the reference doc from Together-only notes to Together + Fireworks coverage
- [x] Verified built-in Fireworks model discovery for Kimi and Qwen
- [x] Proved one-shot Fireworks Kimi and Fireworks Qwen `pi` batch runs in fresh tmux windows
- [x] Wrote this devlog entry

## What changed

Changed:

- `README.md`
- `docs/reference/credentials.md`
- `docs/reference/maintaining-toolnix.md`
- `docs/reference/pi-model-backends.md`
- `docs/devlog/2026-04-22-pi-model-backend-proofs.md`

The main new reference artifact is:

- `docs/reference/pi-model-backends.md`

That doc now covers:

- custom Together models via `~/.pi/agent/models.json`
- built-in Fireworks provider usage via `FIREWORKS_API_KEY`
- current opt-in model IDs and switch commands
- credential injection expectations via `~/.env.toolnix`
- the ownership boundary between repo docs and host-local mutable runtime config

## Verification

Verified Together model discovery and usage earlier in the session with:

```bash
pi --provider together --list-models Qwen/Qwen3-Coder-Next-FP8
pi --provider together --list-models Kimi-K2.5
pi --provider together --model Qwen/Qwen3-Coder-Next-FP8 --thinking off -p "Reply with READY plus one short sentence."
pi --provider together --model moonshotai/Kimi-K2.5 --thinking off -p "Reply with KIMI_OK only."
```

Verified Fireworks built-in model discovery with:

```bash
pi --provider fireworks --list-models kimi
pi --provider fireworks --list-models qwen
```

The visible Fireworks serverless models included:

- `accounts/fireworks/models/kimi-k2p5`
- `accounts/fireworks/models/qwen3-8b`

Verified live Fireworks batch proofs inside fresh tmux windows with:

```bash
pi --provider fireworks --model accounts/fireworks/models/kimi-k2p5 --thinking high -p "Reply with FIREWORKS_KIMI_OK only."
pi --provider fireworks --model accounts/fireworks/models/qwen3-8b --thinking off -p "Reply with FIREWORKS_QWEN_OK only."
```

Observed outputs:

- `FIREWORKS_KIMI_OK`
- `FIREWORKS_QWEN_OK`

## Challenges & Solutions

**Challenges encountered:**
- Early interactive Together tests failed in tmux because `~/.env.toolnix` values were sourced but not exported to child processes.
- The active `tmux-here` session temporarily had a broken/unlinked tmux socket, which made normal tmux control harder during the proof work.
- Sending shell commands into an already-running interactive `pi` pane was noisy and not ideal for deterministic provider validation.

**Solutions found:**
- Switched the Together custom provider path to use a local API-key helper script so `pi` could resolve `TOGETHER_AI_API_KEY` from `~/.env.toolnix` reliably.
- When the tmux socket became available again, used fresh dedicated proof windows for provider validation.
- For Fireworks, preferred clean one-shot batch `pi` invocations in fresh windows over trying to drive interactive panes.

## Learnings

- Fireworks is a real alternative backend path for `pi`, not just a hypothetical one: the built-in `fireworks` provider already exposes usable serverless Kimi and Qwen models in this environment.
- Together still remains useful for exact custom model selection through `models.json`, especially for Together-specific Qwen/Kimi IDs that are not necessarily present as built-in pi provider models.
- The right repo boundary is documentation, not declarative rollout: these model backends are currently best treated as host-local mutable `pi` runtime state plus local secrets in `~/.env.toolnix`.
- For future live provider proofs, fresh tmux batch windows are much more reliable than trying to repurpose an existing interactive `pi` pane.

## Next Steps

- [ ] If Fireworks use becomes routine, add a small note about preferred model IDs or tradeoffs between Together and Fireworks in the reference doc
- [ ] Consider whether any of this should eventually become a declarative host module rather than remaining purely host-local mutable state
- [ ] If more provider comparisons are needed, add a dedicated proof artifact under `docs/proofs/` for repeatable backend validation
