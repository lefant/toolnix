## Summary

`toolnix` project consumers now get the opinionated shell layer by default, with an explicit top-level opt-out and granular sub-switches.

## What Changed

- `modules/devenv/default.nix` now exposes:
  - `toolnix.opinionated.enable`
  - `toolnix.opinionated.timezone.enable`
  - `toolnix.opinionated.aliases.enable`
  - `toolnix.opinionated.tmuxHelpers.enable`
  - `toolnix.opinionated.agentWrappers.enable`
- all of those switches default to `true`
- `toolnix.opinionated.enable = false` disables the entire opinionated shell layer for a project consumer

## Shell Layer Split

`modules/shared/opinionated-shell.nix` now separates the project-facing shell additions into:

- aliases
- agent wrappers
- tmux helpers

That keeps the host-side Home Manager rendering intact while letting the project `devenv` module include or exclude specific `O` features.

## Expected Consumer Shape

Default-on project consumer:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
}
```

Top-level opt-out:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.opinionated.enable = false;
}
```

## Verification

Verified against:

- self-hosted `devenv shell` on `lefant-toolnix`
- published-GitHub project consumption on `asimov-hex`

Default-on behavior expected in interactive `zsh` shells:

- `TZ=Europe/Stockholm`
- `e`
- `claude`
- `codex`
- `tmux-here`

Opt-out behavior expected:

- core required and agent packages still present
- opinionated aliases/functions absent
- timezone override absent

## Notes

- the opinionated layer is injected into the interactive shell path, not into arbitrary nested `bash -lc` subprocesses
- that is acceptable for the intended project-consumer UX, since the feature is about interactive ergonomics rather than bash-compatible shell scripting
