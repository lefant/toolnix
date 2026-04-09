# Fix tmux first-attach status colour

Date: 2026-04-09

## Summary

Fixed an opinionated tmux regression where `tmux-here` could leave a brand-new
session on the default grey status bar on first attach, then show the derived
repo colour only after detaching and attaching again.

The issue reproduced on `lefant-toolnix.exe.xyz` through the normal control-host
meta tmux path:

```bash
ssh -tt lefant-toolnix.exe.xyz 'zsh -ilc "cd ~/git/lefant/toolnix && tmux-here"'
```

The root cause was ordering inside `modules/shared/opinionated-shell.nix`:
`tmux-here` and `tmux-default` applied colour-related server options before the
session existed. On a fresh socket, tmux kept the fallback `status-bg`
(`colour241`) for the first attached client even though `TMUX_COLOUR` had been
computed correctly.

## Changes

- updated `modules/shared/opinionated-shell.nix`
  - added `_tmux-attach-coloured-session`
  - create the target session first when it does not yet exist
  - apply tracked colour/options after session creation
  - attach explicitly to the session instead of relying on `new-session -A`
- added `scripts/check-opinionated-tmux.sh`
  - verifies the first attach from `tmux-here` uses the derived per-repo colour
  - fails if the socket still reports the default grey `status-bg`
- updated maintainer-facing acceptance docs:
  - `README.md`
  - `docs/reference/maintaining-toolnix.md`

## Verification

Local repo verification:

- `nix build .#homeConfigurations.lefant-toolnix.activationPackage`
- `nix run github:cachix/devenv/latest -- shell -- true`
- `bash -n scripts/check-opinionated-tmux.sh`
- `./scripts/check-opinionated-tmux.sh`
  - confirmed the old installed shell still reproduced the bug locally before a
    Home Manager rollout, validating the acceptance check

Remote host reproduction and rollout:

- `lefant-toolnix.exe.xyz`
  - copied the tracked changes into `~/git/lefant/toolnix`
  - reproduced the bug with the new acceptance script before activation:
    - expected derived colour
    - actual first-attach `status-bg=colour241`
  - rebuilt and activated the updated Home Manager config:
    - `nix build .#homeConfigurations.lefant-toolnix.activationPackage`
    - `./result/activate`
  - verified after activation:
    - `./scripts/check-opinionated-zsh.sh`
    - `./scripts/check-opinionated-tmux.sh`
  - re-ran the exact SSH + `tmux-here` path after killing the `toolnix` tmux
    server first and confirmed the first attach now reported the expected
    derived colour (`colour6` for `toolnix@lefant-toolnix`)

## Notes

This change stays within the existing opinionated tmux contract: repo-local tmux
sessions should get a stable derived colour on first attach, not only after a
later reattach. No new spec or ADR was needed; the work restored intended
behavior and made that expectation executable via a tracked acceptance script.
