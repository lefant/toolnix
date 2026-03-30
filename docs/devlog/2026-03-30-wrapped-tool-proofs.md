## Summary

Completed the first wrapped-tool proofs for `toolnix`:

- `toolnix-tmux`
- `toolnix-pi`

These are exported as flake packages/apps and are intended as additive portability proofs on top of the completed dendritic restructuring.

## What changed

Added:

- `flake-parts/wrapped-tools.nix`

Changed:

- `flake-parts/default.nix`

The flake now exports:

- `packages.x86_64-linux.toolnix-tmux`
- `packages.x86_64-linux.toolnix-pi`
- matching app entries for `nix run .#toolnix-tmux` and `nix run .#toolnix-pi`

## Wrapped tmux behavior

`toolnix-tmux`:

- runs tmux with a generated config based on the tracked toolnix tmux defaults
- does not require `~/.tmux.conf`
- can be invoked directly via `nix run .#toolnix-tmux`

Automated proof command:

```bash
nix run .#toolnix-tmux -- start-server ';' show -gv prefix
```

Observed:

- wrapped tmux reports prefix `C-a`, matching toolnix defaults

## Wrapped pi behavior

`toolnix-pi`:

- bootstraps a dedicated agent directory through `PI_CODING_AGENT_DIR`
- seeds tracked toolnix:
  - `settings.json`
  - `keybindings.json`
  - `skills`
- leaves auth local and untracked
- can be invoked directly via `nix run .#toolnix-pi`

The wrapper uses a persistent local state directory by default:

- `PI_CODING_AGENT_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/toolnix/pi/agent`

That means first-run auth via `/login` is compatible with the wrapped path and remains local to the user account.

Automated bootstrap proof command:

```bash
HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_CACHE_HOME="$tmp/cache" \
  nix run .#toolnix-pi -- --help
```

Observed:

- the command runs from a fresh HOME without extra repo setup
- the wrapper creates/symlinks:
  - wrapped `settings.json`
  - wrapped `keybindings.json`
  - wrapped `skills`
- pi starts with the tracked toolnix defaults available through that wrapped state path

## Auth conclusions

### pi

Wrapped pi is a strong fit because it has a clean auth model:

- API keys can come from ordinary environment variables
- subscription auth can be completed interactively with `/login`
- resulting auth state is stored locally under the wrapped pi agent directory

### claude-code and codex

For future wrapped proofs, the likely acceptable model is:

- wrapper provides portable config and non-secret defaults
- first-run auth remains interactive or env-var driven
- auth state stays local to the machine and user account

That is acceptable, but less clean than pi because pi explicitly supports `/login` and `PI_CODING_AGENT_DIR`.

## Fresh-like remote verification

Verified on `lefant-toolbox-nix2` using:

- a fresh temporary HOME
- a fresh temporary repo clone from `main`

Observed remotely:

- `nix run .#toolnix-tmux` uses the wrapped config and reports prefix `C-a`
- `nix run .#toolnix-pi -- --help` works from the fresh repo/home path
- wrapped pi bootstrap creates the expected state/config symlinks

## Notes

- `tmux` and `pi` are now the strongest proven wrapped-tool paths in `toolnix`
- `pi` is the best next candidate for real day-to-day portable single-command use because `/login` makes first-run auth acceptable without extra repo-specific setup
