# Plan: prove llm-agents cache bootstrap on a fresh exe.dev VM

## Date

2026-04-05

## Goal

Prove that a fresh exe.dev VM can bootstrap `toolnix` without falling back to expensive local source builds for the `llm-agents` stack, and record a repeatable verification flow.

Related spec:

- [`docs/specs/llm-agents-cache-bootstrap.md`](../specs/llm-agents-cache-bootstrap.md)

## Acceptance criteria

- `toolnix` publishes the Numtide cache requirement for direct use
- the docs explain that downstream flake recipes must ensure the same cache settings themselves
- a fresh exe.dev VM proof run shows cache configuration before the main build/install path
- the proof run verifies cache-backed behavior with `-L` logs rather than assuming success from elapsed time alone
- the proof run applies a minimal standalone Home Manager bootstrap that imports `toolnix`
- the proof run verifies persistent host files such as `~/.claude/settings.json`, `~/.claude/skills`, and `~/.pi/agent/settings.json`

## Procedure

### 1. Create a fresh VM

Use a new exe.dev VM running the `boldsoftware/exeuntu` image.

Example:

```bash
ssh exe.dev new --name <fresh-name> --image boldsoftware/exeuntu --no-email --json
```

### 2. Verify baseline Nix availability

On the VM, verify:

```bash
command -v nix
nix --version
```

If Nix is missing, install it before continuing.

### 3. Verify direct `toolnix` wrapped-pi cache behavior

Run:

```bash
nix run --accept-flake-config github:lefant/toolnix#toolnix-pi -- --help -L
```

Success signal:

- logs show copying from `https://cache.numtide.com` and/or other binary caches
- logs do not show a large local build chain for the `llm-agents` package stack

Failure signal:

- logs show extensive local building for `pi` or its transitive tool/runtime dependencies
- Nix reports the Numtide cache as untrusted or unavailable

### 4. Create a standalone bootstrap flake for persistent host setup

On the VM, create a minimal flake that imports `toolnix.homeManagerModules.default` and includes the required Numtide cache settings in that recipe.

The recipe should include:

```nix
nixConfig = {
  extra-substituters = [ "https://cache.numtide.com" ];
  extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
};
```

### 5. Apply the bootstrap flake

Run:

```bash
nix run --accept-flake-config github:nix-community/home-manager -- switch --flake ~/.local/share/toolnix-bootstrap#bootstrap
```

### 6. Verify persistent host state

Confirm:

```bash
command -v claude
command -v pi
ls -l ~/.claude/settings.json
ls -l ~/.claude/skills
ls -l ~/.pi/agent/settings.json
```

### 7. Record proof outcome

Capture:

- VM name
- relevant commands used
- whether cache logs showed `cache.numtide.com`
- whether persistent files were installed
- any failures and the iteration/fix applied

## Iteration rule

If any acceptance criterion fails:

1. adjust the relevant repo docs/config
2. create a fresh VM or reset the proof environment
3. rerun the full procedure
4. only mark the proof complete when the fresh-machine run passes without relying on preexisting machine-local cache trust outside the recipe under test
