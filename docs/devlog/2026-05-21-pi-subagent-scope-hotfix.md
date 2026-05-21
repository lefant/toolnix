# Pi subagent extension scope hotfix

Fixed the Compound Engineering Pi subagent extension source path after the Pi package scope migration.

## Context

The agent input refresh moved Toolnix to `pi-0.75.3`. Pi still ships the `examples/extensions/subagent` example, but its installed package path now uses the `@earendil-works/pi-coding-agent` scope instead of the old `@mariozechner/pi-coding-agent` scope. Toolnix was still copying from the old path, causing the `toolnix-patched-pi-subagent-extension` derivation to fail during Home Manager builds.

## Change

Updated `modules/shared/compound-engineering.nix` to resolve the subagent example from known Pi package locations:

1. `@earendil-works/pi-coding-agent/examples/extensions/subagent`
2. `@mariozechner/pi-coding-agent/examples/extensions/subagent`

If neither exists, evaluation throws a clear error instead of failing later with a `cp: cannot stat` builder error.

## Verification

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage --no-link
nix flake check --no-build
```

Both passed. Nix printed the expected restricted-setting warning for this untrusted-user exe.dev environment.

## Follow-up

Vendoring the subagent extension into Toolnix remains a stronger long-term option if Compound Engineering Pi subagent support should be stable across future Pi example layout changes.
