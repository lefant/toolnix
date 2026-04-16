## Summary

Removed `~/.openclaw/openclaw.json` from Home Manager ownership in `toolnix` after a real outage on migrated OpenClaw hosts.

## Why

The tracked template behind the managed Home Manager file was only:

```json
{
  "env": {}
}
```

Because `internal/profiles/home-manager/core.nix` declared:

- `home.file.".openclaw/openclaw.json"`
- with `force = true`

any `home-manager switch` could replace a valid live OpenClaw config with that incomplete Nix store artifact.

That happened on exe.dev OpenClaw hosts and caused gateway startup failures because `gateway.mode` disappeared from the live config.

## What changed

Removed the Home Manager entry that managed:

- `~/.openclaw/openclaw.json`

Also removed the unused tracked stub template:

- `agents/openclaw/templates/openclaw.json`

## New boundary

`toolnix` still manages shell/tmux defaults, shared skill wiring, and other static agent config files, but:

- `~/.openclaw/openclaw.json` is now runtime-owned mutable host state
- OpenClaw onboarding, migration, or explicit host repair owns that file
- normal toolnix rollouts must leave it alone

## Practical result

Future Home Manager rollouts should no longer clobber a valid OpenClaw runtime config with a Nix store symlink.
