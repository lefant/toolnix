---
title: Local Readiness Verification Can Exhaust Small exe.dev VM Disks
date: 2026-05-06
category: workflow-issues
module: Toolnix local readiness verification
problem_type: workflow_issue
component: development_workflow
severity: medium
applies_when:
  - "Running the full Toolnix readiness verification suite on a small exe.dev VM"
  - "Home Manager builds fetch a refreshed llm-agents package closure"
  - "Nix reports database or disk exhaustion during otherwise valid verification"
related_components:
  - Home Manager activation build
  - llm-agents cache prerequisite
  - local Nix store
  - opinionated shell checks
  - wrapped runtime proofs
tags:
  - readiness
  - disk-pressure
  - nix-store
  - exe-dev
  - home-manager
  - verification
---

# Local Readiness Verification Can Exhaust Small exe.dev VM Disks

## Context

After refreshing `llm-agents`, Toolnix needed local readiness verification on `lefant-toolnix`. The verification suite covered the deterministic checks named in `docs/specs/toolnix-agent-readiness.md`: flake evaluation, the Home Manager activation build, the project `devenv` shell, opinionated zsh/tmux checks, and wrapped `toolnix-pi` / `toolnix-tmux` startup proofs.

The first verification pass failed during:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

The build was structurally valid, but the machine had no free space left on `/`. Nix reported:

```text
error: Cannot build '/nix/store/...-home-manager-path.drv'.
       Reason: builder failed with exit code 1.
       note: build failure may have been caused by lack of free disk space
error (ignored): committing transaction: database or disk is full
```

Disk evidence confirmed the real blocker:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        20G   20G     0 100% /
```

Session history for this specific check is the current verification session itself: the retry passed after safe local cleanup, so this was a capacity problem rather than a broken Toolnix module or bad `llm-agents` update (session history).

## Guidance

When local readiness verification fails on a small exe.dev VM, distinguish capacity failures from Toolnix readiness failures before changing Nix code.

Use disk checks early:

```bash
df -h / /nix /home /tmp
du -h -d1 ~/.cache 2>/dev/null | sort -h | tail -30
sudo du -xhd1 / 2>/dev/null | sort -h | tail -30 || du -xhd1 / 2>/dev/null | sort -h | tail -30
```

If `/` is full or nearly full and the failure mentions the Nix database, store transaction, or `home-manager-path`, free non-durable local state before rerunning verification.

Safe cleanup used for the local `lefant-toolnix` verification:

```bash
rm -rf ~/.cache/nix/eval-cache-v6 ~/.cache/puppeteer
nix store gc
```

This freed enough space for the full verification suite:

```text
7064 store paths deleted, 5.5 GiB freed
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        20G   12G  6.7G  65% /
```

Then rerun the full local readiness suite:

```bash
nix flake check --no-build
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
scripts/check-opinionated-zsh.sh
scripts/check-opinionated-tmux.sh
nix run .#toolnix-pi -- --version
nix run .#toolnix-tmux -- -V
```

For the verified local run, the final results were:

```text
nix flake check --no-build                     -> all checks passed
nix build .#homeConfigurations...              -> passed
devenv shell -- true                           -> passed
scripts/check-opinionated-zsh.sh               -> ok: compinit + tracked completion defaults active
scripts/check-opinionated-tmux.sh              -> ok: tmux-here first attach uses derived status-bg colour37
nix run .#toolnix-pi -- --version              -> 0.73.0
nix run .#toolnix-tmux -- -V                   -> tmux 3.6a
```

Also check optional feature applicability so disabled capabilities are not misreported as failures:

```bash
nix eval --json .#homeConfigurations.lefant-toolnix.config.toolnix \
  | jq '{hostName, agentBrowser: .agentBrowser.enable, browserTools: .browserTools.enable, enableHostControl}'
```

For this run:

```json
{
  "hostName": "lefant-toolnix",
  "agentBrowser": false,
  "browserTools": false,
  "enableHostControl": false
}
```

That makes browser automation and host-control readiness **not applicable** for the local default profile.

## Why This Matters

The Home Manager activation build can fetch a large refreshed agent closure from `cache.numtide.com`. On a 20 GiB exe.dev VM, an otherwise correct verification pass can fail simply because previous Nix paths, browser caches, eval caches, or old build artifacts filled the root filesystem.

Treating disk exhaustion as a code failure wastes time and risks unnecessary module changes. Treating it as a `blocked` local-environment condition until cleanup succeeds preserves the readiness vocabulary from the spec: Toolnix is not failing until the check reruns with enough space and still produces an incorrect result.

The expected Nix warning remains separate:

```text
warning: ignoring the client-specified setting 'trusted-public-keys', because it is a restricted setting and you are not a trusted user
```

On this VM, that warning was not the failure. Effective config still included the Numtide substituter and trusted key, and successful reruns copied paths from `https://cache.numtide.com`.

## When to Apply

- A local Toolnix readiness run fails while building `homeConfigurations.lefant-toolnix.activationPackage`.
- Nix reports `database or disk is full`, failed store transactions, or a `home-manager-path` build failure with a disk-space note.
- `/` is near full on an exe.dev VM before or during a lock refresh, Home Manager build, or browser-tool verification.
- The suite has just fetched a refreshed `llm-agents` closure and needs to prove local readiness without confusing cache pressure for config breakage.

## Examples

Bad interpretation:

```text
Home Manager build failed, so the llm-agents refresh broke Toolnix.
```

Better interpretation:

```text
Home Manager build failed while / was 100% full. Cleanup local caches and Nix garbage, then rerun before classifying Toolnix readiness.
```

Minimal triage sequence:

```bash
df -h /
rm -rf ~/.cache/nix/eval-cache-v6 ~/.cache/puppeteer
nix store gc
df -h /
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

Useful report shape after rerun:

```text
Status: pass after local capacity cleanup
Evidence:
- initial / usage: 20G/20G, 0 available
- cleanup: nix store gc freed 5.5 GiB
- final / usage: 15G/20G, 4.0G available
- readiness suite: flake check, Home Manager build, devenv shell, zsh/tmux scripts, wrapped pi/tmux all passed
```

## Related

- `docs/specs/toolnix-agent-readiness.md` — readiness vocabulary and local verification areas.
- `docs/solutions/architecture-patterns/agent-native-readiness-specs-2026-05-04.md` — explains why readiness reports need pass/fail/blocked/not-applicable states.
- `docs/solutions/tooling-decisions/targeted-llm-agents-lock-refreshes-2026-05-06.md` — lock refresh guidance that can trigger the larger agent closure fetch.
- `docs/specs/llm-agents-cache-bootstrap.md` — cache prerequisite for avoiding expensive source builds.
