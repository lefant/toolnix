---
date: 2026-03-28T10:08:10+00:00
researcher: pi
git_commit: ae38b068a1637eb2b0995e37b6b14fd384ca18f0
branch: main
repository: toolnix
topic: "Review of toolnix as the current self-hosted development environment"
tags: [research, codebase, toolnix, devenv, home-manager, agents]
status: complete
last_updated: 2026-03-28
last_updated_by: pi
last_updated_note: "Follow-up added after removing the self-hosted setup hook"
---

# Research: Review of toolnix as the current self-hosted development environment

> Follow-up: this document captures the repo before the self-hosted setup-hook removal completed. For the current architecture, see [`docs/reference/architecture.md`](../reference/architecture.md). For implementation history, see [`docs/devlog/2026-03-28-home-manager-agent-state.md`](../devlog/2026-03-28-home-manager-agent-state.md) and [`docs/devlog/2026-03-28-remove-setup-hook.md`](../devlog/2026-03-28-remove-setup-hook.md).

**Date**: 2026-03-28T10:08:10+00:00  
**Researcher**: pi  
**Git Commit**: `ae38b068a1637eb2b0995e37b6b14fd384ca18f0`  
**Branch**: `main`  
**Repository**: `toolnix`

## Research Question

Review this repo as the current self-hosted development environment for toolnix, focusing on local docs, coding-agent guidance, repo architecture, and likely upcoming work for toolnix itself. Exclude broader control-host and project-consumer concerns except where they still shape the repo.

## Summary

`toolnix` currently presents itself as a public Nix-first shared environment repo with two main consumption paths: a Home Manager host profile and a project-facing `devenv` module ([README.md:3-17](README.md), [flake.nix:21-60](flake.nix), [modules/home-manager/toolnix-host.nix:35-101](modules/home-manager/toolnix-host.nix), [modules/devenv/project.nix:1-16](modules/devenv/project.nix)). The codebase is organized around a small set of shared layers: a required baseline, an opinionated shell layer, an agent baseline, an opt-in `agent-browser` module, and an opt-in host-control layer ([modules/shared/required-baseline.nix:1-27](modules/shared/required-baseline.nix), [modules/shared/opinionated-shell.nix:1-157](modules/shared/opinionated-shell.nix), [modules/shared/agent-baseline.nix:1-81](modules/shared/agent-baseline.nix), [modules/shared/agent-browser.nix:1-43](modules/shared/agent-browser.nix), [modules/shared/host-control.nix:1-55](modules/shared/host-control.nix)).

The current self-hosted workflow is split between declarative Nix modules and an imperative runtime seeding script. The declarative layer manages packages, shell initialization, Home Manager files, and flake exports. The runtime layer seeds and links agent configuration and shared skills into `$HOME`, with separate behavior for host-native shell entry and an older Docker-oriented entrypoint path ([modules/devenv/default.nix:64-114](modules/devenv/default.nix), [modules/home-manager/toolnix-host.nix:48-100](modules/home-manager/toolnix-host.nix), [scripts/toolnix-setup-hook.sh:1-511](scripts/toolnix-setup-hook.sh)).

Documentation currently explains the broad intent and two recent implementation changes, but the repo’s reference surface is still thin: the README gives the high-level shape and the devlogs describe recent toggles and `agent-browser`, while `docs/reference/`, `docs/specs/`, `docs/decisions/`, and `docs/plans/` are still effectively empty ([README.md:119-143](README.md), [docs/devlog/2026-03-27-opinionated-devenv-toggles.md:1-72](docs/devlog/2026-03-27-opinionated-devenv-toggles.md), [docs/devlog/2026-03-28-agent-browser-opt-in-module.md:1-78](docs/devlog/2026-03-28-agent-browser-opt-in-module.md)).

## Detailed Findings

### 1. Top-level architecture and published interfaces

The flake exposes three main interfaces:

- `homeConfigurations.lefant-toolnix`, built from `modules/home-manager/toolnix-host.nix` with a concrete username, home directory, state version, and host label ([flake.nix:21-42](flake.nix))
- `homeManagerModules.default`, which exports the host module for reuse ([flake.nix:44](flake.nix))
- `devenvModules.default`, which wraps `modules/devenv/default.nix` and injects `toolnix` plus the repo’s shared inputs into `args.inputs` ([flake.nix:46-59](flake.nix))

The local `devenv.nix` simply imports `modules/devenv/default.nix`, which makes the repo self-hosting for development in its own shell ([devenv.nix:1-2](devenv.nix)). For external consumers, `modules/devenv/project.nix` reconstructs a merged input set by resolving the local flake and then importing the same shared project module ([modules/devenv/project.nix:1-16](modules/devenv/project.nix)).

The README describes this as a public repo publishing a shared Nix layer with host profiles, `devenv` integration, tracked agent config, and shared skills, and it frames the intended consumption path as read-only GitHub flake refs plus local path overrides for active development ([README.md:3-17](README.md)).

### 2. Shared module layering inside the repo

The codebase implements a layered environment model across `modules/shared/`.

`required-baseline.nix` defines the narrow mandatory package baseline and locale environment. It distinguishes between a broader package set for project shells and a smaller Home Manager package set to avoid profile ownership collisions on deployed hosts ([modules/shared/required-baseline.nix:1-27](modules/shared/required-baseline.nix)).

`opinionated-shell.nix` defines interactive shell behavior shared across host and project usage. It includes editor alias logic, `claude` and `codex` wrapper aliases, tmux helper functions, zsh prompt/history configuration, and tmux defaults. It also exposes rendering helpers that allow project shells to include or exclude subsets of that shell layer ([modules/shared/opinionated-shell.nix:3-157](modules/shared/opinionated-shell.nix)).

`agent-baseline.nix` resolves `agent-skills` and `llm-agents`, constructs a managed skill tree and manifest, exposes a `toolnix-claude-statusline` helper, and adds the main agent package set (`claude-code`, `codex`, `beads`, `opencode`, `pi`, `amp`) plus environment flags that suppress agent auto-update behavior ([modules/shared/agent-baseline.nix:1-81](modules/shared/agent-baseline.nix)).

`agent-browser.nix` is intentionally separate from the always-on agent baseline. It provides a wrapper binary that lazily installs `agent-browser@0.22.3` into host-local user state, then execs the real CLI. It also exports environment variables for browser state, npm prefix, and npm cache paths ([modules/shared/agent-browser.nix:1-43](modules/shared/agent-browser.nix)).

`host-control.nix` defines a distinct host-control shell addition that is off by default in the host module. It exports an inventory root variable, wraps `target-ssh.sh`, and defines a dedicated `tmux-meta` session with its own prefix and status color scheme ([modules/shared/host-control.nix:1-55](modules/shared/host-control.nix)).

### 3. Project-shell model (`devenv`)

The project-shell module composes the shared layers into a project-local shell.

`modules/devenv/default.nix` defines:

- `toolnix.agentBrowser.enable` as an opt-in project shell feature ([modules/devenv/default.nix:14-18](modules/devenv/default.nix))
- `toolnix.opinionated.enable` and four nested opinionated sub-switches for timezone, aliases, tmux helpers, and agent wrappers ([modules/devenv/default.nix:20-48](modules/devenv/default.nix))

The resulting shell package set is:

- required baseline packages
- a general interactive/dev package set including `zsh`, `emacs-nox`, `vim`, `fzf`, `tree`, `htop`, `ncdu`, `ripgrep`, `jq`, `curl`, `wget`, `socat`, `openssh`, `rsync`, `unzip`, `shellcheck`, `procps`, and `less`
- agent baseline packages
- optional `agent-browser` wrapper package when enabled ([modules/devenv/default.nix:64-83](modules/devenv/default.nix))

The shell environment merges required locale env, optional opinionated timezone env, agent env, optional `agent-browser` env, and default `EDITOR`/`VISUAL` settings ([modules/devenv/default.nix:85-92](modules/devenv/default.nix)).

On shell entry, the module exports source directories, sets the timezone if enabled, injects agent baseline shell state, injects selected opinionated shell functions/aliases, sources either `~/.env.toolnix` or `~/.env.toolbox`, and then runs the setup hook in seed-only mode ([modules/devenv/default.nix:94-114](modules/devenv/default.nix)).

The recent devlog documents that the opinionated layer was intentionally split into granular toggles and enabled by default for project consumers, while remaining top-level opt-outable ([docs/devlog/2026-03-27-opinionated-devenv-toggles.md:1-72](docs/devlog/2026-03-27-opinionated-devenv-toggles.md)).

### 4. Host-shell model (Home Manager)

The host module composes the same shared layers into a Home Manager-managed shell environment.

`modules/home-manager/toolnix-host.nix` defines host options for:

- `toolnix.hostName` ([modules/home-manager/toolnix-host.nix:11-15](modules/home-manager/toolnix-host.nix))
- `toolnix.enableHostControl` ([modules/home-manager/toolnix-host.nix:17-21](modules/home-manager/toolnix-host.nix))
- `toolnix.enableAgentBaseline` ([modules/home-manager/toolnix-host.nix:23-27](modules/home-manager/toolnix-host.nix))
- `toolnix.agentBrowser.enable` ([modules/home-manager/toolnix-host.nix:29-33](modules/home-manager/toolnix-host.nix))

Its `home.packages` include the narrower required baseline plus optional agent baseline and optional `agent-browser` support ([modules/home-manager/toolnix-host.nix:38-41](modules/home-manager/toolnix-host.nix)). `home.sessionVariables` always include the opinionated shell timezone env on hosts, along with required env and any optional agent layers ([modules/home-manager/toolnix-host.nix:42-46](modules/home-manager/toolnix-host.nix)).

The host module writes the managed zsh and tmux config files, sources `~/.env.toolnix` or `~/.env.toolbox` from `~/.zsh/zshlocal.sh`, links git and SSH config files from `home-manager/files/`, and conditionally provides a separate meta tmux config when host-control is enabled ([modules/home-manager/toolnix-host.nix:48-82](modules/home-manager/toolnix-host.nix)).

It also defines a Home Manager activation step that merges or seeds `~/.claude.json` from `agents/claude/templates/dot-claude.json` after link generation ([modules/home-manager/toolnix-host.nix:84-100](modules/home-manager/toolnix-host.nix)).

### 5. Runtime seeding and managed agent state

The runtime setup path is implemented by `scripts/toolnix-setup-hook.sh`, which is described in its header as an idempotent environment initialization script that can run either as a Docker entrypoint or as a host-native `devenv` enter-shell hook ([scripts/toolnix-setup-hook.sh:1-18](scripts/toolnix-setup-hook.sh)).

The script supports two main behavior modes:

- default mode: initialize and then `exec "$@"` ([scripts/toolnix-setup-hook.sh:9-11](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:502-511](scripts/toolnix-setup-hook.sh))
- `TOOLNIX_SEED_ONLY=1`: initialize only, then exit ([scripts/toolnix-setup-hook.sh:9-11](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:505-507](scripts/toolnix-setup-hook.sh))

It seeds or links config for:

- Claude Code ([scripts/toolnix-setup-hook.sh:77-130](scripts/toolnix-setup-hook.sh))
- Codex ([scripts/toolnix-setup-hook.sh:132-146](scripts/toolnix-setup-hook.sh))
- OpenCode ([scripts/toolnix-setup-hook.sh:148-164](scripts/toolnix-setup-hook.sh))
- Amp ([scripts/toolnix-setup-hook.sh:166-182](scripts/toolnix-setup-hook.sh))
- OpenClaw ([scripts/toolnix-setup-hook.sh:184-199](scripts/toolnix-setup-hook.sh))
- Pi Coding Agent ([scripts/toolnix-setup-hook.sh:201-223](scripts/toolnix-setup-hook.sh))

For managed skill installation, it either:

- symlinks a prebuilt managed tree when `TOOLNIX_MANAGED_SKILL_MANIFEST` resolves to a built skill tree and there are no compound-engineering runtime extras to merge ([modules/shared/agent-baseline.nix:44-50](modules/shared/agent-baseline.nix), [modules/shared/agent-baseline.nix:77-80](modules/shared/agent-baseline.nix), [scripts/toolnix-setup-hook.sh:228-418](scripts/toolnix-setup-hook.sh))
- or builds a writable overlay directory from the managed tree, manifest, raw skills source, and optional compound-engineering skill sources ([scripts/toolnix-setup-hook.sh:306-381](scripts/toolnix-setup-hook.sh))

The script then symlinks most agents’ skill directories back to `~/.agents/skills`, while treating Codex separately because it preserves bundled internal skills under `~/.codex/skills/.system` ([scripts/toolnix-setup-hook.sh:384-418](scripts/toolnix-setup-hook.sh)).

The script also retains Docker-oriented mount writability checks and optional plugin installation and converted command/agent installation paths for Claude, Codex, and OpenCode ([scripts/toolnix-setup-hook.sh:49-75](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:107-129](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:421-477](scripts/toolnix-setup-hook.sh)).

### 6. Current documentation set and recent repo history

The README is the primary top-level document. It describes the repo as a public Nix-first development environment and host-profile repo, names the intended consumption modes, documents the basic project-consumer import shape, shows project-level opt-out and `agent-browser` opt-in toggles, and includes common commands for entering the host or project shell on `lefant-toolnix` ([README.md:1-117](README.md)).

The README also defines a documentation taxonomy and an AI-assisted development workflow of Research -> Plan -> Implement -> Devlog ([README.md:119-143](README.md)).

The repo’s current `docs/devlog/` directory contains two implementation notes:

- opinionated `devenv` toggles ([docs/devlog/2026-03-27-opinionated-devenv-toggles.md:1-72](docs/devlog/2026-03-27-opinionated-devenv-toggles.md))
- opt-in `agent-browser` support ([docs/devlog/2026-03-28-agent-browser-opt-in-module.md:1-78](docs/devlog/2026-03-28-agent-browser-opt-in-module.md))

The recent commit history aligns with that documentation sequence: path-importable project module support, injected toolnix inputs, default-on opinionated shell behavior, README usage examples, opt-in `agent-browser`, first-run docs, and lockfile tracking.

## Architecture Summary

In its current form, `toolnix` is a layered self-hosted environment repo where:

- `flake.nix` publishes both host and project entrypoints ([flake.nix:21-60](flake.nix))
- `modules/shared/*` define the reusable layers ([modules/shared/required-baseline.nix:1-27](modules/shared/required-baseline.nix), [modules/shared/opinionated-shell.nix:1-157](modules/shared/opinionated-shell.nix), [modules/shared/agent-baseline.nix:1-81](modules/shared/agent-baseline.nix), [modules/shared/agent-browser.nix:1-43](modules/shared/agent-browser.nix), [modules/shared/host-control.nix:1-55](modules/shared/host-control.nix))
- `modules/devenv/default.nix` assembles those layers into a self-hosted or consumer-facing project shell with toggleable opinionated behavior and optional browser support ([modules/devenv/default.nix:14-114](modules/devenv/default.nix))
- `modules/home-manager/toolnix-host.nix` assembles the same layers into a Home Manager-managed host shell and activation flow ([modules/home-manager/toolnix-host.nix:35-101](modules/home-manager/toolnix-host.nix))
- `scripts/toolnix-setup-hook.sh` bridges the declarative layer into runtime agent state under `$HOME` ([scripts/toolnix-setup-hook.sh:1-511](scripts/toolnix-setup-hook.sh))

## Maintenance Model and Boundaries Observed in the Repo

The repo presents itself as the shared source of truth for:

- shared Nix environment layers ([README.md:7-12](README.md))
- Home Manager host profiles ([README.md:9-10](README.md), [flake.nix:40-44](flake.nix))
- `devenv` integration for project consumers ([README.md:11](README.md), [modules/devenv/project.nix:1-16](modules/devenv/project.nix))
- tracked agent configuration and shared skills ([README.md:12](README.md), [agents/](agents), [modules/shared/agent-baseline.nix:19-80](modules/shared/agent-baseline.nix))

Within that structure, the code also preserves a narrower boundary for host-control concerns: `toolnix.enableHostControl` defaults to `false`, and the control helpers live in their own shared module rather than being mixed into the baseline host shell ([modules/home-manager/toolnix-host.nix:17-21](modules/home-manager/toolnix-host.nix), [modules/shared/host-control.nix:1-55](modules/shared/host-control.nix)).

The repo also maintains a distinction between always-on baseline behavior and opt-in features:

- project-shell opinionated ergonomics are default-on but toggleable ([modules/devenv/default.nix:20-62](modules/devenv/default.nix))
- `agent-browser` is opt-in for both project and host usage ([modules/devenv/default.nix:14-18](modules/devenv/default.nix), [modules/home-manager/toolnix-host.nix:29-33](modules/home-manager/toolnix-host.nix), [docs/devlog/2026-03-28-agent-browser-opt-in-module.md:1-78](docs/devlog/2026-03-28-agent-browser-opt-in-module.md))

## Documentation Gaps and Contradictions

### Gaps observed

- The README describes `A/R/O/H` baselines but does not directly map them onto the concrete module files under `modules/shared/` ([README.md:7-12](README.md), [modules/shared/](modules/shared)).
- There is no dedicated reference document describing the runtime seeding path implemented by `scripts/toolnix-setup-hook.sh` even though that script is central to the self-hosted agent workflow ([scripts/toolnix-setup-hook.sh:1-511](scripts/toolnix-setup-hook.sh)).
- The docs taxonomy in `README.md` names `docs/reference/`, `docs/specs/`, `docs/decisions/`, and `docs/plans/`, but those directories are currently represented only by `.gitkeep` files ([README.md:121-139](README.md), [docs/reference/.gitkeep](docs/reference/.gitkeep), [docs/specs/.gitkeep](docs/specs/.gitkeep), [docs/decisions/.gitkeep](docs/decisions/.gitkeep), [docs/plans/.gitkeep](docs/plans/.gitkeep)).
- There is no repo-local coding-agent guidance document that narrows future work to toolnix-specific architecture, docs, and self-hosted workflow concerns.

### Mixed signals observed

- The README frames `toolnix` as a public Nix-first repo while also describing it as publishing a shared layer “currently prototyped in `toolbox`” ([README.md:3-8](README.md)).
- Both the project-shell and host-shell paths still source `~/.env.toolbox` as a fallback after `~/.env.toolnix` ([modules/devenv/default.nix:103-111](modules/devenv/default.nix), [modules/home-manager/toolnix-host.nix:54-65](modules/home-manager/toolnix-host.nix)).
- The self-hosted docs emphasize host-native use, but the setup hook still includes Docker entrypoint language, `/opt/...` path defaults, Docker writability checks, and compound-engineering plugin conversion/install paths ([scripts/toolnix-setup-hook.sh:1-18](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:49-75](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:107-129](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:421-477](scripts/toolnix-setup-hook.sh)).
- The recent devlogs document project-consumer proofs against `asimov-hex`, while the present review scope for this repo is focused on toolnix itself and its self-hosted maintenance path ([docs/devlog/2026-03-27-opinionated-devenv-toggles.md:47-66](docs/devlog/2026-03-27-opinionated-devenv-toggles.md), [docs/devlog/2026-03-28-agent-browser-opt-in-module.md:57-72](docs/devlog/2026-03-28-agent-browser-opt-in-module.md)).

## Coding-Agent Guidance to Capture for Future Sessions

Based on the current repo shape, the following guidance is directly supported by the codebase and documentation structure and would fit as repo-local working guidance for future agent sessions:

- treat `toolnix` itself as the unit of work, with primary focus on local docs, module boundaries, host-shell/project-shell behavior, and self-hosted workflow support
- treat `modules/shared/host-control.nix` as an opt-in host-control layer rather than part of the main toolnix baseline ([modules/home-manager/toolnix-host.nix:17-21](modules/home-manager/toolnix-host.nix), [modules/shared/host-control.nix:1-55](modules/shared/host-control.nix))
- preserve the distinction between required baseline, opinionated shell behavior, agent baseline, and optional browser/control extensions when making changes ([modules/shared/required-baseline.nix:1-27](modules/shared/required-baseline.nix), [modules/shared/opinionated-shell.nix:1-157](modules/shared/opinionated-shell.nix), [modules/shared/agent-baseline.nix:1-81](modules/shared/agent-baseline.nix), [modules/shared/agent-browser.nix:1-43](modules/shared/agent-browser.nix))
- treat `scripts/toolnix-setup-hook.sh` as part of the runtime contract for this repo, since both self-hosted and legacy paths still depend on it ([modules/devenv/default.nix:113](modules/devenv/default.nix), [scripts/toolnix-setup-hook.sh:1-511](scripts/toolnix-setup-hook.sh))
- record behavior changes in repo-local docs, because the README and devlogs are currently the only maintained documentation sources with substantive content ([README.md:119-143](README.md), [docs/devlog/2026-03-27-opinionated-devenv-toggles.md:1-72](docs/devlog/2026-03-27-opinionated-devenv-toggles.md), [docs/devlog/2026-03-28-agent-browser-opt-in-module.md:1-78](docs/devlog/2026-03-28-agent-browser-opt-in-module.md))

## Highest-Value Next Work Items for Toolnix

The current codebase and docs suggest the following toolnix-local follow-up areas:

1. Add reference documentation for the repo’s architecture and module layering, covering flake outputs, host vs project entrypoints, and the role of each shared module.
2. Add reference documentation for runtime seeding and managed agent state, centered on `scripts/toolnix-setup-hook.sh`.
3. Add repo-local coding-agent guidance so future sessions start from toolnix’s current boundaries instead of older consumer/control-host assumptions.
4. Clarify legacy versus current paths in docs around `toolbox`, `.env.toolbox`, Docker entrypoint behavior, and compound-engineering plugin handling.
5. Continue filling the declared documentation structure under `docs/reference/`, `docs/decisions/`, and `docs/plans/` so the documented workflow in `README.md` matches the repo’s actual documentation surface.

## Prototype-Like or Earlier-Assumption Coupling Still Visible

The following patterns remain visible in the current codebase as carryovers from earlier environment assumptions:

- `host-control.nix` is explicitly tied to `hackbox-ctrl-inventory` and `hackbox-ctrl-utils` path conventions ([modules/shared/host-control.nix:6-13](modules/shared/host-control.nix))
- both shell entry paths still fall back to `~/.env.toolbox` ([modules/devenv/default.nix:103-111](modules/devenv/default.nix), [modules/home-manager/toolnix-host.nix:57-65](modules/home-manager/toolnix-host.nix))
- the setup hook still carries Docker entrypoint and `/opt/...` defaults, Docker mount checks, plugin marketplace installation, and compound-engineering converted asset installation ([scripts/toolnix-setup-hook.sh:1-18](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:49-75](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:107-129](scripts/toolnix-setup-hook.sh), [scripts/toolnix-setup-hook.sh:421-477](scripts/toolnix-setup-hook.sh))
- the README still describes `toolnix` partly in terms of a publication or migration path from `toolbox` and mentions `asimov-hex` as an early project-consumer proof ([README.md:7-8](README.md), [README.md:19-23](README.md))
- the documentation structure is broader than the currently populated documentation corpus ([README.md:121-143](README.md), [docs/](docs))

## Code References

- `flake.nix:21-60` - flake outputs for host config, Home Manager module export, shared devenv sources, and default devenv module wrapper
- `devenv.nix:1-2` - local self-hosted shell import path
- `modules/devenv/project.nix:1-16` - path-importable project consumer module with merged toolnix inputs
- `modules/devenv/default.nix:14-114` - project-shell options, package/env composition, shell entry behavior, and setup hook invocation
- `modules/home-manager/toolnix-host.nix:11-100` - host options, package/session configuration, file management, and activation hook
- `modules/shared/required-baseline.nix:1-27` - required baseline packages and locale environment
- `modules/shared/opinionated-shell.nix:3-157` - aliases, agent wrappers, tmux helpers, zsh config, and tmux config rendering helpers
- `modules/shared/agent-baseline.nix:19-80` - managed skill tree/manifest generation and agent package/env setup
- `modules/shared/agent-browser.nix:1-43` - lazy host-native `agent-browser` wrapper and state env vars
- `modules/shared/host-control.nix:5-55` - opt-in control-host shell additions and meta tmux session
- `scripts/toolnix-setup-hook.sh:77-223` - agent config initialization functions
- `scripts/toolnix-setup-hook.sh:228-418` - shared skill tree linking and fanout logic
- `scripts/toolnix-setup-hook.sh:421-477` - converted compound-engineering asset installation
- `docs/devlog/2026-03-27-opinionated-devenv-toggles.md:1-72` - recent documentation of opinionated project-shell toggles
- `docs/devlog/2026-03-28-agent-browser-opt-in-module.md:1-78` - recent documentation of opt-in browser support

## Related Research

- None in `docs/research/` at the time of writing.

## Open Questions

- Which parts of `scripts/toolnix-setup-hook.sh` remain part of the intended long-term host-native contract versus retained compatibility behavior?
- Whether `~/.env.toolbox` fallback is still considered an active compatibility requirement or only a transition path.
- Whether `host-control.nix` is meant to remain in this repo as a permanently quarantined opt-in module or move behind a more explicit boundary in future documentation.
