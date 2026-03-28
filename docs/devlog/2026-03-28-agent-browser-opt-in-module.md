## Summary

Added opt-in host-native `agent-browser` support to `toolnix` as a separate module-level concern instead of folding it into the always-on agent baseline.

## Design

- `agent-browser` remains outside the shared mandatory `A` baseline
- project consumers opt in with:

```nix
toolnix.agentBrowser.enable = true;
```

- Home Manager hosts can also opt in with the same nested option
- default consumers remain unchanged

## Implementation

Added:

- `modules/shared/agent-browser.nix`

Wired into:

- `modules/devenv/default.nix`
- `modules/home-manager/toolnix-host.nix`

The shared module provides:

- a managed `agent-browser` wrapper on `PATH`
- host-local state locations for:
  - npm prefix
  - npm cache
  - browser runtime state

## Runtime model

The wrapper follows the accepted host-install direction:

- no Docker requirement
- installs the real CLI into host-local user state on first use
- preserves the upstream browser install flow via:

```bash
agent-browser install
```

State paths:

- npm prefix:
  - `~/.local/share/toolnix/agent-browser/npm-prefix`
- npm cache:
  - `~/.cache/toolnix-agent-browser/npm`
- browser state:
  - `~/.agent-browser`

## Consumer proof

`asimov-hex` was used as the first project consumer proof with:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.agentBrowser.enable = true;
}
```

Verified:

- opt-in consumers get `agent-browser` on `PATH`
- ordinary consumers remain unchanged
- default path does not require Docker

## Notes

- this v1 is intentionally minimal and reversible
- the real CLI install still happens lazily on first `agent-browser` invocation
- browser runtime installation remains an explicit user step via `agent-browser install`
