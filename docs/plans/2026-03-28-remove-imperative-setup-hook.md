# Plan: remove imperative setup hook from the self-hosted toolnix workflow

## Goal

Migrate the self-hosted `toolnix` environment away from `scripts/toolnix-setup-hook.sh` and into Nix-native ownership, with Home Manager owning persistent user configuration and `devenv` owning shell-local behavior only.

## Scope

In scope:

- `toolnix` self-hosted host workflow
- Home Manager ownership of persistent agent config and skills wiring
- removal of automatic hook execution from the self-hosted `devenv` shell path
- cleanup of now-unused hook-specific environment exports and docs
- architecture and devlog updates

Out of scope for this plan:

- control-host / inventory workflows beyond preserving explicit opt-in boundaries
- older Docker/container entrypoint behavior
- project-consumer compatibility work unless needed to keep core modules coherent

## Current dependency on the hook

Today the hook is still invoked from the self-hosted `devenv` shell path:

- `modules/devenv/default.nix`

The hook currently handles two broad classes of work:

1. legacy / transitional behavior
   - `/opt/...` path defaults
   - Docker mount writability checks
   - Claude marketplace plugin installation
   - compound-engineering plugin and converted asset installation

2. still-active runtime setup
   - seeding/linking agent config files under `$HOME`
   - linking the shared skills tree into agent-specific locations

## Target ownership model

### Home Manager host owns persistent runtime state

Move persistent configuration into declarative Home Manager ownership:

- `~/.claude/settings.json`
- `~/.codex/config.toml`
- `~/.config/opencode/opencode.json`
- `~/.config/amp/settings.json`
- `~/.openclaw/openclaw.json`
- `~/.pi/agent/settings.json`
- `~/.pi/agent/keybindings.json`
- `~/.agents/skills`
- agent skill directory symlinks where appropriate

Keep the existing `.claude.json` merge behavior under Home Manager activation unless/until a cleaner declarative replacement is agreed.

### Devenv owns shell-local behavior only

`devenv` should retain:

- packages
- shell env
- aliases/functions
- optional features such as `agent-browser`

`devenv` should stop mutating persistent `$HOME` state on shell entry.

## Migration steps

### Step 1 — Add stable docs entrypoints

- [x] add minimal `docs/reference/architecture.md`
- [x] add README pointers to architecture and this plan
- [x] symlink `AGENTS.md` and `CLAUDE.md` to `README.md`

### Step 2 — Move persistent agent config and skills wiring into Home Manager

- [x] expose the managed skill tree from `modules/shared/agent-baseline.nix`
- [x] manage agent config files via `home.file` in `modules/home-manager/toolnix-host.nix`
- [x] manage shared skills and agent skill symlinks declaratively in Home Manager
- [x] verify Home Manager activation package builds successfully

### Step 3 — Remove setup-hook use from the self-hosted devenv path

- [x] stop invoking `scripts/toolnix-setup-hook.sh` from `modules/devenv/default.nix`
- [x] remove now-unused hook-specific shell exports from shared modules if no longer needed
- [x] smoke test `devenv shell`

### Step 4 — Remove the obsolete hook and legacy assumptions

- [x] delete `scripts/toolnix-setup-hook.sh` after removing its last code path
- [x] remove stale references in code
- [x] refresh older research/docs that still described the hook as current

### Step 5 — Finalize docs after migration completes

- [x] expand `docs/reference/architecture.md` to reflect the completed post-hook architecture
- [x] write devlogs summarizing the migration

## Verification

At each implementation step:

- run `nix build .#homeConfigurations.lefant-toolnix.activationPackage`
- run a self-hosted shell smoke test with `devenv shell -- true`
- inspect resulting git diff for any leftover references to the setup hook

## Commit strategy

Use small commits:

1. docs and symlink entrypoints
2. Home Manager ownership of persistent agent state
3. devenv hook removal and cleanup
4. final docs/devlog cleanup
