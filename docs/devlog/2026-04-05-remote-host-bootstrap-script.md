## Summary

Added a tracked public bootstrap script for `toolnix` host setup that can run on a fresh machine without a target-side `toolnix` git clone. The script installs Nix if needed, configures the Numtide cache prerequisite for fresh exeuntu-style hosts, renders a minimal standalone Home Manager bootstrap flake, and activates `toolnix.homeManagerModules.default`.

## What changed

Changed:

- `scripts/bootstrap-home-manager-host.sh`
- `README.md`
- `docs/reference/maintaining-toolnix.md`

## Why

The repo now has an explicit remote-flake bootstrap decision and a fresh-environment bootstrap spec. This script is the minimal tracked artifact that hands off from pre-Nix setup to Nix-managed `toolnix` host state while keeping credentials machine-local.

## Notes

- the script defaults to `github:lefant/toolnix` and therefore treats remote flake consumption as the bootstrap default
- it still attempts machine-local cache configuration because fresh exeuntu VMs with Determinate multi-user Nix need more than flake `nixConfig` alone
- it does not attempt to provision credentials; that remains the caller's responsibility
