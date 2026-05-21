# Pi login URL padding hotpatch

Added a Toolnix-managed Pi extension that hotpatches `LoginDialogComponent.showAuth` at extension-load time.

## Why

Pi 0.75.3 still renders the OAuth login URL with left padding:

```ts
new Text(theme.fg("accent", linkedUrl), 1, 0)
```

When terminal wrapping inserts indentation into copied text, the `/login` URL can become unusable unless the terminal is widened or font size is reduced.

## Implementation

- Added `agents/pi-coding-agent/extensions/login-url-padding.ts`.
- The extension imports Pi's exported `LoginDialogComponent`, wraps `showAuth`, then changes the rendered URL `Text` component's `paddingX` to `0` after the original method builds the dialog. This preserves upstream styling and browser-opening behavior while removing the copy-breaking left padding.

- Wired the extension into both Toolnix Pi entry points:
  - Home Manager-managed `~/.pi/agent/extensions/login-url-padding.ts`
  - wrapped `toolnix-pi` state under `~/.local/state/toolnix/pi/agent/extensions/login-url-padding.ts`

This is intentionally a narrow runtime hotpatch until upstream Pi removes the padding or exposes a proper setting.

## Validation

```bash
nix build .#toolnix-pi
nix run .#toolnix-pi -- --version
```

Also started wrapped Pi in tmux with `--verbose` and confirmed startup lists:

```text
~/.local/state/toolnix/pi/agent/extensions/login-url-padding.ts
```

## Caveat

This depends on Pi continuing to export `LoginDialogComponent`. If upstream changes that component name or moves login rendering behind a non-exported path, the extension will need an update or removal.
