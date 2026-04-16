## Summary

Enabled the shipped Pi `qna` example as a tracked default Pi extension in `toolnix`.

This makes `/qna` available in both:

- the Home Manager-managed `~/.pi/agent/` runtime
- the wrapped `toolnix-pi` runtime

## What changed

Added:

- `agents/pi-coding-agent/extensions/qna.ts`
- `docs/devlog/2026-04-16-pi-qna-default-extension.md`

Changed:

- `internal/profiles/home-manager/core.nix`
- `flake-parts/wrapped-tools.nix`

## Why

`/qna` is a useful lightweight question-extraction workflow:

- ask Pi something that ends in questions
- run `/qna`
- Pi extracts those questions from the last assistant message
- the extension loads a Q/A template into the editor for completion and submission

Because `toolnix` already manages tracked Pi runtime state declaratively, the right place to enable this by default is the tracked Pi extension path rather than ad hoc local copies.

## Notes

The extension content is the shipped upstream Pi example from:

- `examples/extensions/qna.ts`

The implementation wires it into both default consumption paths so behavior stays aligned between:

- normal Home Manager-managed Pi use
- `nix run .#toolnix-pi`
