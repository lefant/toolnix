# Credentials and Auth in Toolnix

This document describes how `toolnix` expects credentials to be provided.

The core rule is:

- `toolnix` manages tool configuration and shell wiring
- credentials and secrets are injected locally, outside the repo
- coding agents and Git should receive credentials through standard user-level mechanisms rather than tracked repo state

See also:

- [`architecture.md`](architecture.md)
- [`maintaining-toolnix.md`](maintaining-toolnix.md)
- [`../decisions/2026-03-30_export-wrapped-tmux-and-pi-proofs.md`](../decisions/2026-03-30_export-wrapped-tmux-and-pi-proofs.md)

## Design intent

`toolnix` is a Nix-managed environment repo, not a secrets store.

That means:

- no API keys or tokens are tracked in this repo
- no secret material is embedded in Nix modules or agent templates
- local machines are expected to provide credentials through env files, CLI auth state, SSH agent state, or machine-local config files

## Expected credential injection paths

## 1. Environment files for runtime secrets

For local runtime secrets, `toolnix` expects environment variables to be provided through:

- `~/.env.toolnix`
- legacy fallback: `~/.env.toolbox`

These files are sourced in both main entry paths:

- Home Manager host shells via `~/.zsh/zshlocal.sh`
- `devenv` shells via `modules/devenv/default.nix`

This is the main generic injection path for API keys and similar runtime credentials.

Typical examples include provider credentials such as:

- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- other local tokens needed by CLI tools or coding agents

## 2. GitHub HTTPS credentials via `gh`

GitHub HTTPS auth is expected to be provided by authenticated `gh` CLI state.

`toolnix` installs a Git include file that configures:

- GitHub HTTPS credential lookup through `gh auth git-credential`

This means Git operations against matching GitHub remotes rely on:

- `gh` being installed
- the local user having already authenticated with `gh`

`toolnix` wires the helper, but does not perform the login itself.

## 3. SSH credentials via local SSH config and agent state

SSH is expected to come from ordinary user-level SSH state, not repo-managed secrets.

`toolnix` tracks a shared `~/.ssh/config` base file which includes:

- `~/.ssh/config.local`

That means machine-specific SSH details should live in local files or local SSH agent state, for example:

- private key selection in `~/.ssh/config.local`
- agent-provided identities via `SSH_AUTH_SOCK`
- host-specific overrides in local SSH config

## 4. Tool-specific local auth state

Some coding tools rely on their own local login state in addition to or instead of plain env vars.

Examples in the tracked config:

- Claude settings force `claudeai` login mode
- OpenCode config references `ANTHROPIC_API_KEY` via env interpolation for Anthropic
- GitHub HTTPS auth is delegated to `gh`

`toolnix` manages the config files that point to these mechanisms, but the actual authenticated state stays local to the machine and user account.

## Current self-hosted example

In the current self-hosted `lefant-toolnix` setup, credentials are provided roughly like this:

### Shell/runtime secrets

Local secrets live outside the repo in:

- `~/.env.toolnix`

That file is sourced automatically by:

- the Home Manager-managed zsh startup path
- the `devenv` shell entry path

### GitHub auth

Git is configured to use the `gh` credential helper for GitHub HTTPS remotes.

In practice, that means the user logs in with `gh` locally and Git reuses that authenticated state.

### SSH auth

SSH host-specific details remain local through:

- `~/.ssh/config.local`
- the local SSH agent / forwarded agent state

### Coding-agent auth

Coding-agent packages and config files are installed declaratively by `toolnix`, but credentials still come from local runtime state such as:

- env vars loaded from `~/.env.toolnix`
- local tool login state
- CLI-managed auth stores where the tool supports them

Wrapped-tool proofs follow the same rule.

Current wrapped pi behavior:

- `nix run .#toolnix-pi` seeds tracked config and skills automatically
- auth can then come from env vars or interactive `/login`
- wrapped pi auth state remains local under the wrapped pi agent directory, by default:
  - `${XDG_STATE_HOME:-~/.local/state}/toolnix/pi/agent/auth.json`

A future wrapped `claude-code` or `codex` path should follow the same ownership rule:

- wrapper-managed config is acceptable
- machine-local auth state is acceptable
- tracked secrets in this repo are not

## What toolnix manages vs does not manage

### Toolnix manages

- shell wiring that loads local env files
- Git config that points GitHub HTTPS auth to `gh`
- base SSH config that includes a machine-local override file
- tracked agent config files and package installation

### Toolnix does not manage

- secret values
- API keys or tokens
- `gh` login state
- SSH private keys
- local machine-specific SSH overrides
- external provider account setup

## Bootstrap credential-injection modes

The same declarative `toolnix` target state can be reached through more than one credential-injection mode.

### 1. Standalone bootstrap

This is the mode for a fresh machine that has no relationship to an existing control host.

Typical properties:

- public GitHub refs only
- no privileged `GH_TOKEN` from another system
- no preexisting SSH trust to another managed host
- credentials are injected manually on the machine itself

Typical standalone credential steps:

- create or edit `~/.env.toolnix`
- run `gh auth login`
- perform tool-local interactive login where needed
- add any machine-local SSH details in `~/.ssh/config.local`

### 2. Control-host-assisted bootstrap

This is the mode for a fresh machine being created from an existing control-host workflow.

Typical properties:

- declarative `toolnix` state should still be the same as in standalone bootstrap
- secrets still remain machine-local and outside tracked repo state
- credential material may be injected by the control-host workflow instead of by a human sitting at the new machine

Typical control-host-assisted credential steps may include:

- writing `~/.env.toolnix` from a trusted control-host-side secret source
- placing machine-local SSH overrides or known-good host files
- pre-populating local CLI auth state where the external workflow explicitly owns that step

Important boundary:

- the difference between these modes should be **how machine-local credentials arrive**
- the difference should **not** be a different declarative `toolnix` runtime model

## Practical guidance

When adding or changing tools in `toolnix`:

- prefer env-var based secret injection unless a tool has a stronger native local auth model
- document any required env vars or login prerequisites in `docs/reference/`
- keep tracked config free of secret values
- use machine-local includes or local auth stores for machine-specific auth details
- when documenting bootstrap, state clearly whether a step belongs to standalone manual injection or to a control-host-assisted workflow

## Notes

- `.claude.json` remains a special-case host activation merge, but it should still not contain tracked secret values from this repo.
- The `~/.env.toolbox` fallback remains only as a legacy compatibility path.
