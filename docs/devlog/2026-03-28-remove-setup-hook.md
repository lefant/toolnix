## Summary

Completed the self-hosted migration away from the imperative setup hook.

## What Changed

### Devenv shell path

`modules/devenv/default.nix` no longer invokes `scripts/toolnix-setup-hook.sh` on shell entry.

The self-hosted/project shell now limits itself to:

- exporting `TOOLNIX_SOURCE_DIR`
- setting shell-local environment
- loading opinionated shell helpers
- sourcing `~/.env.toolnix` or `~/.env.toolbox`

That removes persistent `$HOME` mutation from the `devenv` shell path.

### Shared agent baseline cleanup

`modules/shared/agent-baseline.nix` now exposes only the managed skill tree needed for declarative Home Manager wiring.

The previous hook-era shell export plumbing is no longer part of the shared agent baseline.

### Hook removal

`scripts/toolnix-setup-hook.sh` has been removed.

That also removes the old Docker-era and plugin-era setup path from the repo, including:

- `/opt/...` fallback assumptions
- Docker mount writability checks
- marketplace/plugin install logic
- compound-engineering converted asset installation path

## Verification

Verified with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

Results:

- Home Manager activation package built successfully after hook removal
- `devenv shell` still entered successfully without invoking any runtime setup hook

## Notes

- persistent self-hosted agent state is now owned by Home Manager instead of shell-entry mutation
- `docs/reference/architecture.md` is still intentionally minimal until the final post-migration architecture write-up is expanded
