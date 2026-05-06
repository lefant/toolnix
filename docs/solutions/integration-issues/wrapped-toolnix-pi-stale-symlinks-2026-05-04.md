---
title: Wrapped toolnix-pi Must Replace Stale Managed Symlinks
date: 2026-05-04
category: integration-issues
module: wrapped toolnix-pi runtime
problem_type: integration_issue
component: assistant
symptoms:
  - "`nix run --accept-flake-config .#toolnix-pi -- --version` failed with `ln: failed to create symbolic link ... File exists`"
  - "Broken symlinks under `~/.local/state/toolnix/pi/agent` made `[ ! -e target ]` true while `ln -s` still failed because the directory entry existed"
  - "Home Manager-managed `~/.pi/agent/settings.json` still worked, so ordinary `pi --version` did not expose the wrapped-runtime failure"
root_cause: config_error
resolution_type: code_fix
severity: medium
related_components:
  - Toolnix wrapped runtime proofs
  - Pi managed settings
  - Home Manager profile
  - agent readiness verification
tags:
  - toolnix-pi
  - symlinks
  - wrapped-runtime
  - nix-run
  - readiness
  - pi
---

# Wrapped toolnix-pi Must Replace Stale Managed Symlinks

## Problem

The wrapped `toolnix-pi` proof failed on `lefant-toolnix` after validation found stale broken symlinks in the wrapper-owned runtime state under `~/.local/state/toolnix/pi/agent`. The wrapper treated broken managed symlinks as missing because `[ ! -e target ]` is true for broken symlinks, then tried to create a new symlink at an already-existing path and exited before Pi could start.

## Symptoms

- `nix run --accept-flake-config .#toolnix-pi -- --version` failed during wrapper startup:

  ```text
  ln: failed to create symbolic link '/home/exedev/.local/state/toolnix/pi/agent/settings.json': File exists
  ```

- After fixing `settings.json`, the same pattern appeared for the managed skill tree:

  ```text
  ln: failed to create symbolic link '/home/exedev/.local/state/toolnix/pi/agent/skills': File exists
  ```

- Inspecting the state directory showed wrapper-owned paths were stale symlinks into garbage-collected Nix store outputs:

  ```text
  /home/exedev/.local/state/toolnix/pi/agent/settings.json: broken symbolic link to /nix/store/...-settings.json
  ```

- The normal Home Manager-managed Pi path still worked:

  ```text
  pi --version
  0.70.2
  ```

  That made this a wrapped-runtime readiness issue, not proof that all Pi entry points were broken.

## What Didn't Work

- Running only `pi --version` did not catch the issue because it uses the Home Manager-managed `~/.pi/agent` state, not the isolated wrapped `toolnix-pi` state.
- Fixing only `settings.json` would have left the same failure mode for `keybindings.json`, `AGENTS.md`, extensions, `skills`, or `auth.json` if any of those wrapper-owned symlinks became stale.
- The original `[ ! -e "$target" ]` guard was insufficient. POSIX `test -e` returns false for broken symlinks, but `ln -s` still refuses to create a new entry at the same path.
- Session history search found no relevant prior sessions within the requested 7-day window (session history).

## Solution

Replace the repeated one-off symlink creation checks in `flake-parts/wrapped-tools.nix` with a helper that handles three cases explicitly:

1. missing path: create the managed symlink;
2. broken symlink: replace it with the current managed Nix store path;
3. existing real file, directory, or live symlink: preserve it.

Before:

```bash
if [ ! -e "$agent_dir/settings.json" ]; then
  ln -s "${piSettings}" "$agent_dir/settings.json"
fi

if [ ! -e "$agent_dir/skills" ]; then
  ln -s "${agent.managedSkillTree}" "$agent_dir/skills"
fi
```

After:

```bash
link_managed_file() {
  local source="$1"
  local target="$2"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$source" "$target"
  elif [ -L "$target" ] && [ ! -e "$target" ]; then
    ln -sfn "$source" "$target"
  fi
}

link_managed_file "${piSettings}" "$agent_dir/settings.json"
link_managed_file "${piKeybindings}" "$agent_dir/keybindings.json"
link_managed_file "${piAgents}" "$agent_dir/AGENTS.md"
link_managed_file "${piQnaExtension}" "$agent_dir/extensions/qna.ts"
link_managed_file "${piAskUserExtension}" "$agent_dir/extensions/ask-user.ts"
link_managed_file "${piLoopExtension}" "$agent_dir/extensions/loop.ts"
link_managed_file "${agent.managedSkillTree}" "$agent_dir/skills"

if [ -f "$HOME/.pi/agent/auth.json" ]; then
  link_managed_file "$HOME/.pi/agent/auth.json" "$agent_dir/auth.json"
fi
```

The same helper is used for every wrapper-managed symlink so future stale state does not fail one path at a time.

Validation on `lefant-toolnix`:

```bash
nix run --accept-flake-config .#toolnix-pi -- --version
# 0.73.0

git diff --check
nix flake check --accept-flake-config
scripts/check-opinionated-zsh.sh
scripts/check-opinionated-tmux.sh
devenv test
```

`nix flake check` passed. The shell/tmux checks passed. `devenv test` passed with the existing note that no `enterTest` command is defined and the local `devenv` binary is newer than the lock input.

## Why This Works

`-e` checks whether the symlink target exists, not whether the symlink directory entry exists. For a broken symlink, `[ ! -e "$target" ]` is true, but the path is still occupied by a symlink, so plain `ln -s "$source" "$target"` fails with `File exists`.

`-L` checks whether the path itself is a symlink. Combining `-L` with `! -e` identifies exactly the stale managed-link case. `ln -sfn` can then atomically repoint the symlink to the current Nix store object.

Preserving existing non-symlink paths keeps the wrapper from overwriting local user state. This matters for paths such as `auth.json`, where a real file or valid link may intentionally carry machine-local credentials.

## Prevention

- For Nix-managed wrapper state, treat stale symlinks as a first-class state transition. Do not rely on `[ ! -e path ]` alone when the path may be a symlink into the Nix store.
- Use one helper for all wrapper-managed links so fixes cover settings, keybindings, context files, extensions, skills, and optional auth wiring together.
- Verify wrapped runtime proofs with `nix run .#toolnix-pi -- --version` or `--help`, not just the host-profile `pi` binary on `PATH`.
- Include a stateful rerun scenario in readiness checks: run once, allow the referenced store paths to change over time, then run again with existing wrapper state.
- Distinguish host-profile readiness from wrapped-runtime readiness in reports. A working `~/.pi/agent` path does not prove `~/.local/state/toolnix/pi/agent` is healthy.

## Related Issues

- [`docs/solutions/integration-issues/pi-ask-user-compound-tool-2026-04-29.md`](pi-ask-user-compound-tool-2026-04-29.md) covers a different wrapped `toolnix-pi` integration issue: missing Pi `ask_user` tool wiring.
- [`docs/solutions/architecture-patterns/agent-native-readiness-specs-2026-05-04.md`](../architecture-patterns/agent-native-readiness-specs-2026-05-04.md) explains why wrapped runtime proofs are a distinct Toolnix readiness area.
- [`docs/devlog/2026-03-30-wrapped-tool-proofs.md`](../../devlog/2026-03-30-wrapped-tool-proofs.md) records the original wrapped `toolnix-pi` state design under `~/.local/state/toolnix/pi/agent`.
- [`docs/specs/toolnix-agent-readiness.md`](../../specs/toolnix-agent-readiness.md) defines the readiness vocabulary used to classify this as a wrapped-runtime `fail` before the fix.
