## Summary

Started the setup-hook migration by moving persistent self-hosted agent runtime state into declarative Home Manager ownership.

## What Changed

### Shared agent baseline

`modules/shared/agent-baseline.nix` now exposes:

- `managedSkillTree`
- `managedSkillManifest`

That makes the managed skill tree reusable outside the previous shell-hook path.

The module now also keeps `enterShell = ""` so existing `devenv` composition remains valid while the migration is still in progress.

### Home Manager host ownership

`modules/home-manager/toolnix-host.nix` now manages these persistent files directly via `home.file`:

- `~/.claude/settings.json`
- `~/.codex/config.toml`
- `~/.config/opencode/opencode.json`
- `~/.config/amp/settings.json`
- `~/.openclaw/openclaw.json`
- `~/.pi/agent/settings.json`
- `~/.pi/agent/keybindings.json`

It also manages the shared skill tree declaratively for:

- `~/.agents/skills`
- `~/.claude/skills`
- `~/.config/opencode/skills`
- `~/.config/amp/skills`
- `~/.openclaw/skills`
- `~/.pi/agent/skills`

Codex skill fanout remains excluded at this step because the existing runtime model preserves Codex internal `.system` skills separately.

## Verification

Verified with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

Results:

- Home Manager activation package built successfully
- `devenv shell` still worked after the shared-module change
- the old setup hook is still being invoked from `devenv` at this point, but persistent host state now has a declarative Home Manager path

## Notes

- this step intentionally preserves the current `devenv` behavior while shifting persistent state ownership to Home Manager first
- the next migration step is to remove automatic setup-hook invocation from `modules/devenv/default.nix` and then delete the obsolete hook code path
