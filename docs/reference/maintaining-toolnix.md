# Maintaining Toolnix

This document covers the practical maintainer workflow for the self-hosted `toolnix` repo.

See also:

- [`architecture.md`](architecture.md)
- [`credentials.md`](credentials.md)
- [`../specs/fresh-environment-bootstrap.md`](../specs/fresh-environment-bootstrap.md)
- [`../specs/llm-agents-cache-bootstrap.md`](../specs/llm-agents-cache-bootstrap.md)
- [`../plans/2026-04-05-bootstrap-paths-and-credentials.md`](../plans/2026-04-05-bootstrap-paths-and-credentials.md)
- [`../plans/2026-04-05-exe-vm-bootstrap-proof.md`](../plans/2026-04-05-exe-vm-bootstrap-proof.md)
- [`../plans/2026-03-28-remove-imperative-setup-hook.md`](../plans/2026-03-28-remove-imperative-setup-hook.md)

## What owns what

### Home Manager owns persistent host state

Persistent self-hosted runtime state under `$HOME` is managed by `modules/home-manager/toolnix-host.nix`, including:

- shell and tmux config
- git and SSH config
- persistent agent config files
- shared skills wiring
- session variables
- `.claude.json` activation-time merge behavior

### Devenv owns shell-local behavior

`modules/devenv/default.nix` shapes the active shell only:

- packages
- shell-local environment
- aliases and helper functions
- optional shell features such as `agent-browser`

`devenv` should not be used to provision persistent host runtime state.

### Local secret state stays outside the repo

Local runtime secrets and credentials are still loaded from:

- `~/.env.toolnix`
- legacy fallback: `~/.env.toolbox`

These files are local-only and not repo-managed.

## Common maintainer commands

### Enter the self-hosted project shell

```bash
devenv shell
```

### Non-interactive shell smoke test

```bash
devenv shell -- true
```

### Build the Home Manager activation package

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

### Apply the Home Manager configuration locally

Build first:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

Then activate the result:

```bash
./result/activate
```

### Inspect recent changes while working

```bash
git status
git log --oneline -n 10
```

## Recommended workflow for repo changes

1. Read the current architecture and any active plan docs first.
2. Make small changes in either:
   - Home Manager host ownership, or
   - `devenv` shell behavior,
   but avoid mixing concerns unless the change requires both.
3. Verify with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

4. Record notable behavior changes in `docs/devlog/`.
5. Commit in small steps.

## Typical change categories

### Host-state changes

Examples:

- adding or changing managed files under `$HOME`
- wiring new persistent agent config
- changing shared skill directory ownership
- updating shell/tmux/git/ssh host defaults

Primary file:

- `modules/home-manager/toolnix-host.nix`

Verify with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

### Project-shell changes

Examples:

- adding packages to the shell
- adjusting aliases or helper functions
- changing opinionated shell toggles
- adding optional `devenv` features

Primary files:

- `modules/devenv/default.nix`
- `modules/shared/opinionated-shell.nix`
- `modules/shared/agent-browser.nix`
- `modules/shared/required-baseline.nix`
- `modules/shared/agent-baseline.nix`

Verify with:

```bash
devenv shell -- true
```

### Architecture or boundary changes

Examples:

- changing ownership between Home Manager and `devenv`
- changing published flake/module interfaces
- changing repo-maintenance guidance

Update:

- `docs/reference/architecture.md`
- `README.md`
- relevant plan/devlog docs

## State locations

### Repo-managed sources

Tracked configuration sources live under:

- `agents/`
- `modules/`
- `home-manager/files/`
- `docs/`

### Persistent host state

Persistent host state lives under `$HOME`, including:

- `~/.claude/`
- `~/.codex/`
- `~/.config/opencode/`
- `~/.config/amp/`
- `~/.openclaw/`
- `~/.pi/agent/`
- `~/.agents/skills`

### Optional browser state

When `agent-browser` is enabled, host-local state lives under:

- `~/.agent-browser`
- `~/.local/share/toolnix/agent-browser/npm-prefix`
- `~/.cache/toolnix-agent-browser/npm`

## Binary cache note

`toolnix` uses `github:numtide/llm-agents.nix` as a flake input for the tracked agent CLIs.

The repo publishes the Numtide cache requirement in `flake.nix` via flake `nixConfig` so direct commands such as wrapped-tool proofs can use it.

For direct use, prefer:

```bash
nix run --accept-flake-config github:lefant/toolnix#toolnix-pi
```

Important multi-user Nix note:

- on fresh exeuntu VMs with a Determinate multi-user Nix install, ordinary users are not trusted to add arbitrary substituters
- in that environment, flake `nixConfig` alone is not sufficient to trust `cache.numtide.com`
- add the Numtide cache to machine-local trusted Nix settings first, for example via `/etc/nix/nix.custom.conf`

For that environment, use machine-local settings such as:

```conf
extra-substituters = https://cache.numtide.com
extra-trusted-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

Important scope rule:

- direct use of `toolnix` can rely on the cache settings published by `toolnix`
- a downstream flake that imports `toolnix` should not assume those cache settings propagate automatically from the input
- any flake recipe that depends on `llm-agents.nix`, directly or transitively, must ensure the required cache settings in its own recipe or machine-local Nix config before expensive builds begin

Required cache settings:

```conf
extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

Keep the standard `cache.nixos.org` cache enabled as well.

For diagnostics, compare:

```bash
nix config show | rg 'substituters|trusted-substituters|trusted-public-keys|extra-substituters|extra-trusted-substituters|extra-trusted-public-keys'
nix run -L --accept-flake-config github:lefant/toolnix#toolnix-pi -- --help
```

A healthy cache path should show Nix copying from caches rather than building large dependency chains locally.

Related artifacts:

- [`../specs/llm-agents-cache-bootstrap.md`](../specs/llm-agents-cache-bootstrap.md)
- [`../plans/2026-04-05-exe-vm-bootstrap-proof.md`](../plans/2026-04-05-exe-vm-bootstrap-proof.md)

## Notes

- `.claude.json` is intentionally still a special-case activation merge.
- Historical devlogs may describe earlier states of the repo; prefer `architecture.md` for the current model.
- `host-control` remains opt-in and is not part of the default self-hosted maintenance path.
