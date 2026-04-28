## Summary

Added an auto-heal path to the host bootstrap script for a broken user-local Nix Git cache at `~/.cache/nix/tarball-cache-v2`.

## What changed

Changed:

- `scripts/bootstrap-home-manager-host.sh`

Added:

- `docs/devlog/2026-04-28-bootstrap-host-git-cache-auto-heal.md`

## Why

`lefant-ctrl.exe.xyz` hit a bootstrap failure during `nix flake metadata github:lefant/toolnix` even though machine-local cache configuration was otherwise correct.

The failing stderr shape was:

- `opening Git repository ".../tarball-cache-v2": could not find repository`

In this state, the bootstrap script aborted before Home Manager activation. The cache directory is disposable derived state, so moving the broken path aside and retrying is the correct recovery.

## Notes

- the new logic only auto-heals the specific observed failure mode
- on a matching error, it moves `tarball-cache-v2` aside to a timestamped `.broken-<utc>` path and retries `nix flake metadata`
- if the retry still fails, the script preserves the original stderr and exits as before
- verified with a local fake-`nix` harness and a real rerun of `scripts/provision-toolnix-host.sh lefant-ctrl.exe.xyz`
- the real rerun on `lefant-ctrl.exe.xyz` logged the auto-heal warning and then completed successfully
