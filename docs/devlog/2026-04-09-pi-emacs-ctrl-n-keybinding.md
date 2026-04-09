## Summary

Updated the tracked pi keybindings template so `ctrl+n` behaves like standard Emacs cursor-down in the pi editor, and removed the default session named-filter binding that would otherwise conflict.

## What changed

Changed:

- `agents/pi-coding-agent/templates/keybindings.json`

Keybinding updates:

- added `ctrl+n` to `tui.editor.cursorDown`
- set `app.session.toggleNamedFilter` to `[]` so `ctrl+n` is no longer claimed by the session picker

## Why

`toolnix` manages `~/.pi/agent/keybindings.json` declaratively from the tracked pi template, so the correct persistent fix is to update the template rather than editing the live file by hand.

This keeps both:

- the Home Manager-managed host path
- the wrapped `toolnix-pi` bootstrap path

in sync with the same Emacs-style behavior.

## Notes

The relevant wiring remains:

- `internal/profiles/home-manager/core.nix`
- `flake-parts/wrapped-tools.nix`

Both source pi keybindings from `agents/pi-coding-agent/templates/keybindings.json`.
