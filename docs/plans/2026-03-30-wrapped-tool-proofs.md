# Plan: wrapped-tool proofs for tmux and pi

## Goal

Add the first post-restructure wrapped-tool proofs to `toolnix`, focusing on the two highest-value candidates:

- `tmux`
- `pi`

These proofs should validate that a user on a fresh VM with a fresh repo checkout can run the tool through a single `nix run` command without any additional repo-specific setup.

## Why these two first

### tmux

`tmux` is a strong wrapped-tool candidate because:

- it already has a clear, tracked configuration shape in `toolnix`
- it does not require external authentication
- the acceptance path is easy to verify automatically

### pi

`pi` is the strongest agent candidate because:

- `toolnix` already tracks pi settings and keybindings
- pi supports explicit config-dir overrides via `PI_CODING_AGENT_DIR`
- pi supports `/login`, so first-run auth can be interactive without any extra repo-specific setup
- pi auto-discovers skills from the configured agent directory, which fits a wrapped portable state model well

## Scope

In scope:

- export wrapped `tmux` and wrapped `pi` packages from the flake
- keep the current host/devenv behavior unchanged
- verify on `lefant-toolbox-nix2`
- document the auth model for wrapped tools

Out of scope for this proof:

- full wrapped exports for every agent tool
- replacing Home Manager or `devenv` with wrappers
- solving first-run auth non-interactively for subscription-based tools

## Acceptance tests

### tmux

On a fresh HOME and fresh repo checkout:

```bash
nix run .#toolnix-tmux
```

For automated verification, it is sufficient to prove the wrapped config is being used, for example by checking key config values such as the prefix.

### pi

On a fresh HOME and fresh repo checkout:

```bash
nix run .#toolnix-pi
```

Expected behavior:

- pi starts without requiring prior repo-specific config installation
- tracked toolnix settings and keybindings are available
- tracked skills are available
- auth can be completed interactively via `/login`, or via environment variables if already present

For automated verification, it is sufficient to prove that the wrapped command bootstraps its config/state correctly and can start from a fresh HOME without extra setup.

## Auth model

### pi

Wrapped pi should support two acceptable auth paths:

- existing env vars (for example from `~/.env.toolnix`)
- first-run interactive `/login`

The wrapper should manage config and skill wiring, but not embed credentials.

### claude-code / codex

For later wrapped proofs, the likely model is:

- wrapper provides config and any portable non-secret defaults
- first-run auth remains local and interactive, or comes from env vars / local auth stores
- wrapper-managed state directories may isolate tool-specific auth, but should not attempt to ship secrets in Nix

## Implementation steps

### Step 1 — add wrapped package outputs

Add flake package outputs for:

- `toolnix-tmux`
- `toolnix-pi`

### Step 2 — wire tracked config into the wrappers

- tmux wrapper should use tracked toolnix tmux configuration directly
- pi wrapper should seed/configure:
  - settings
  - keybindings
  - skills
  - persistent local auth/session state directory

### Step 3 — verify on a fresh-like environment

On `lefant-toolbox-nix2`:

- use a fresh temporary HOME
- use a fresh temporary repo clone
- verify wrapped tmux
- verify wrapped pi bootstrap/startup behavior

### Step 4 — document proof results

- write a devlog
- document the auth handling conclusions for future wrapped proofs

## Current status

Implementation now includes:

- `toolnix-tmux` flake package/app
- `toolnix-pi` flake package/app
- remote fresh-like verification on `lefant-toolbox-nix2` using a temporary HOME and temporary repo clone
- documented auth conclusions for wrapped pi and future wrapped agent tools

## Definition of done

This plan is done when:

- `toolnix-tmux` and `toolnix-pi` are exported from the flake
- both work from a fresh HOME and fresh repo checkout on `lefant-toolbox-nix2`
- pi auth expectations are documented clearly
- the next wrapped-tool candidates are clearer as a result of the proof

## Outcome

Done.
