---
title: HITL Browser Automation Runtime Needs curl
date: 2026-05-29
category: integration-issues
module: Toolnix HITL browser automation
problem_type: integration_issue
component: tooling
symptoms:
  - "The opt-in HITL runtime could install hitl-browser-hub without installing curl"
  - "Code review found Browser Debug Hub uses curl for CDP readiness and smoke-app HTTP checks"
  - "Existing package checks could pass while a Home Manager-enabled runtime still missed a required command"
root_cause: missing_tooling
resolution_type: environment_setup
severity: high
related_components:
  - "Home Manager profile packages"
  - "devenv profile packages"
  - "agent-skills Browser Debug Hub"
  - "flake check package assertions"
tags: [toolnix, hitl-browser-automation, curl, nix, runtime-dependencies, browser-tools]
---

# HITL Browser Automation Runtime Needs curl

## Problem

`toolnix.hitlBrowserAutomation.enable` was added to expose the skill-owned `hitl-browser-hub` workflow and install its runtime dependencies. The first implementation installed the hub wrapper, `agent-browser`, Chromium environment variables, Node.js, Python, `jq`, and VNC/display tools, but omitted `curl` even though the Browser Debug Hub scripts call `curl` at runtime.

That meant the declarative option could appear valid in Nix evaluation and package-composition checks while still producing an enabled environment that could fail once the hub tried to wait for CDP, poll the smoke app, or run smoke tests.

## Symptoms

- Reviewers flagged `modules/shared/hitl-browser-automation.nix` because `packages` did not include `pkgs.curl`.
- Browser Debug Hub uses `curl` for runtime readiness and HTTP checks, for example CDP `/json/version`, smoke-app `/api/state`, and smoke/recorder test requests.
- The initial Toolnix check covered `hitl-browser-hub`, `agent-browser`, Node.js, Python, `jq`, TigerVNC, and Chromium env binding, but did not assert `curl` in both Home Manager and devenv enabled package lists.

## What Didn't Work

- Relying on `nix flake check --no-build` alone was not enough. It proved evaluation, but not every runtime command required by the skill-owned scripts.
- The first `hitl-browser-automation-packages` check proved several dependencies and wrapper path behavior, but because it did not include `curl`, it could still pass with an incomplete runtime closure.
- Disk-pressure failures during validation were a separate local-capacity issue, not the dependency omission.

## Solution

Add `pkgs.curl` to `modules/shared/hitl-browser-automation.nix`:

```nix
packages = [
  hitlBrowserHub
  pkgs.nodejs
  pkgs.python3
  pkgs.jq
  pkgs.curl
] ++ vncPackages;
```

Then make the package check encode that dependency contract for both supported consumers:

```nix
${lib.optionalString (!(hasPackage pkgs.curl hitlPackages) || !(hasPackage pkgs.curl hitlDevenvPackages)) ''
  echo "curl should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
  exit 1
''}
```

Validate with:

```bash
nix build .#checks.x86_64-linux.hitl-browser-automation-packages --print-out-paths
nix flake check --no-build
```

## Why This Works

The skill package remains portable and continues to own the Browser Debug Hub scripts. Toolnix only supplies the commands those scripts expect to find in an enabled environment.

Adding `pkgs.curl` to `modules/shared/hitl-browser-automation.nix` fixes the runtime environment for both Home Manager and devenv because both profiles consume the shared `hitlBrowserAutomation.packages` list. Adding the check in `flake-parts/features/hitl-browser-automation.nix` prevents drift: future edits that remove `curl` from either enabled package list fail the cheap Nix check before users hit a runtime error.

This also preserves the two-layer architecture:

- `agent-skills` owns workflow behavior and Browser Debug Hub implementation.
- Toolnix owns declarative dependency and environment provisioning.
- Checks prove the boundary by verifying wrapper presence, skill-command availability, environment variables, and required runtime commands without running the full browser/VNC stack on every evaluation.

## Prevention

- When wrapping a skill-owned command in Toolnix, inspect the skill scripts for every external command they invoke outside the shell baseline. Add each required command to the opt-in package set or document why it is intentionally host-provided.
- Pair every new runtime dependency with a package-composition assertion for both Home Manager and devenv. Do not rely on one profile as a proxy for the other.
- Keep cheap checks focused on declarative contract coverage: package inclusion, default-light invariants, wrapper path existence, and environment binding.
- Treat browser/VNC/CDP smoke tests as a separate runtime validation layer. They prove plumbing, but they should not be the only place missing CLI dependencies are discovered.
- Classify disk exhaustion during validation separately from module correctness. Free local Nix/cache state and rerun before deciding whether a Toolnix change is broken.

## Related Issues

- `docs/solutions/tooling-decisions/nix-browser-tool-cache-friendly-repack-2026-05-05.md` — related browser-tool packaging pattern; low-to-moderate overlap on browser runtime checks and cache-friendly validation.
- `docs/solutions/workflow-issues/local-readiness-verification-disk-pressure-2026-05-06.md` — related validation caveat for small exe.dev disks; useful for separating capacity failures from real module defects.
