## Summary

Enabled the `loop` extension as a tracked default Pi extension in `toolnix`.

This makes `/loop` and the supporting `signal_loop_success` tool available in both:

- the Home Manager-managed `~/.pi/agent/` runtime
- the wrapped `toolnix-pi` runtime

## What changed

Added:

- `agents/pi-coding-agent/extensions/loop.ts`
- `docs/devlog/2026-04-16-pi-loop-default-extension.md`

Changed:

- `internal/profiles/home-manager/core.nix`
- `flake-parts/wrapped-tools.nix`

## Why

`/loop` provides a bounded iterative follow-up workflow for Pi.

It can:

- loop until tests pass
- loop until a custom condition is satisfied
- loop until the agent decides it is done

The extension persists loop state, surfaces status in the UI, and includes compaction-aware handling so the breakout condition survives session compaction.

## Notes

The extension content comes from the reviewed upstream reference:

- `mitsuhiko/agent-stuff/extensions/loop.ts`

As with `qna`, the implementation is wired into both default consumption paths so behavior stays aligned between:

- normal Home Manager-managed Pi use
- `nix run .#toolnix-pi`
