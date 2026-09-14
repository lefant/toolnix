# toolnix

Public Nix-first development environment and host-profile repo.

## Start Here

- Architecture reference: [`docs/reference/architecture.md`](docs/reference/architecture.md)
- Agent readiness spec: [`docs/specs/toolnix-agent-readiness.md`](docs/specs/toolnix-agent-readiness.md)
- Credentials reference: [`docs/reference/credentials.md`](docs/reference/credentials.md)
- Pi model backends reference: [`docs/reference/pi-model-backends.md`](docs/reference/pi-model-backends.md)
- Fresh-environment bootstrap spec: [`docs/specs/fresh-environment-bootstrap.md`](docs/specs/fresh-environment-bootstrap.md)
- Fresh-environment bootstrap plan: [`docs/plans/2026-04-05-bootstrap-paths-and-credentials.md`](docs/plans/2026-04-05-bootstrap-paths-and-credentials.md)
- Setup-hook migration plan: [`docs/plans/2026-03-28-remove-imperative-setup-hook.md`](docs/plans/2026-03-28-remove-imperative-setup-hook.md)

## Scope

`toolnix` is the shared Nix layer for:

- shared `A/R/O/H` baselines
- Home Manager host profiles
- `devenv` integration for project consumers
- tracked agent config and shared skills

The intended consumption modes are:

- read-only GitHub flake refs for projects and hosts
- local `path:` overrides for active development

## Current goals

- support self-hosted development on `lefant-toolnix`
- provide a clean published interface for project consumers
- keep host-native runtime state declarative and Nix-managed

## Repo boundaries

When working in `toolnix`, prioritize:

- `toolnix` docs, architecture, and module boundaries
- self-hosted workflow quality on `lefant-toolnix`
- the published Nix interface exposed by this repo

Do not treat these as the default focus here:

- control-host or inventory workflow expansion
- downstream project-consumer implementation details
- assumptions that require SSH access to consumer hosts

`modules/shared/host-control.nix` remains opt-in for inventory/control-host wrappers such as `target-entry` and `targets`.

`tmux-meta` is available by default as a harmless secondary tmux session wrapper.

## Project Consumer Shape

Minimal project consumer:

```yaml
# devenv.yaml
inputs:
  toolnix:
    url: github:lefant/toolnix
```

```nix
# devenv.nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
}
```

Opinionated shell defaults are enabled by default for project consumers.

Top-level opt-out:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.opinionated.enable = false;
}
```

Optional Nix-managed `agent-browser` support for project consumers:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.agentBrowser.enable = true;
}
```

Optional full browser-tools support for project consumers:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.browserTools.enable = true;
}
```

Optional human-in-the-loop browser automation runtime support:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.hitlBrowserAutomation.enable = true;
}
```

This provides the skill-owned `hitl-browser-hub` command plus `agent-browser`, Toolnix Chromium env, Node.js, Python, `jq`, and VNC/display tools. In Home Manager, shared skills are installed persistently for supported agents. In `devenv`, Toolnix provides shell-local commands and dependencies; agent skill discovery still depends on the host agent configuration or direct skill-path use.

### Browser Tools First Run

`toolnix.agentBrowser.enable` provides the Nix-packaged `agent-browser` CLI and points it at Toolnix's Nix-managed Chromium. No npm first-run install or `agent-browser install` browser download is required for normal use.

Minimal first-run flow:

```bash
agent-browser --version
```

Ordinary usage works without Docker:

```bash
agent-browser open https://example.com
agent-browser wait --load networkidle
agent-browser get title
agent-browser close
```

`toolnix.browserTools.enable` implies the `agent-browser` behavior above and also provides `vhs` plus the shared Chromium package:

```bash
vhs --version
chromium --version
```

Host-local runtime state used by the opt-in integrations:

- browser runtime state: `~/.agent-browser`
- HITL browser automation state: `${XDG_STATE_HOME:-$HOME/.local/state}/hitl-browser-automation/<project-name>-<hash>/`

Older hosts that used the previous lazy npm wrapper may still have cleanup-safe convenience state under:

- npm prefix: `~/.local/share/toolnix/agent-browser/npm-prefix`
- npm cache: `~/.cache/toolnix-agent-browser/npm`

HITL browser automation first-run flow in an enabled environment:

```bash
hitl-browser-hub check
hitl-browser-hub start
hitl-browser-hub status
hitl-browser-hub stop
```

For remote VM use, keep VNC and CDP loopback-bound and use explicit SSH local forwarding as printed by `hitl-browser-hub start`. Raw browser profiles, traces, screenshots, cookies, and logs are sensitive and should not be committed.

Other host-local runtime convenience state may also exist outside the durable project layout, for example a librarian-style reference-repo cache under `~/.cache/checkouts/<host>/<org>/<repo>`.

That checkout cache is optional convenience state, not a canonical repo location, and is a valid cleanup target when disk space runs low.

## Common Commands

### Wrapped portable tools

Bootstrap a fresh host with the tracked Home Manager bootstrap script:

```bash
curl -fsSL https://raw.githubusercontent.com/lefant/toolnix/main/scripts/bootstrap-home-manager-host.sh | bash -s --
```

Optional host-label override:

```bash
curl -fsSL https://raw.githubusercontent.com/lefant/toolnix/main/scripts/bootstrap-home-manager-host.sh | bash -s -- --host-name my-host
```

By default, `--host-name` is optional and resolves to `hostname -s`. It controls the short `toolnix.hostName` label used by the host config, primarily for host-facing shell/tmux display context.

This installs Nix if needed, configures the required cache settings for fresh exeuntu-style hosts, renders a minimal standalone bootstrap flake, and activates `toolnix.homeManagerModules.default` without requiring a target-side `toolnix` git clone.

Run the wrapped tmux proof directly from a repo checkout:

```bash
nix run .#toolnix-tmux
```

This uses the tracked toolnix tmux defaults without requiring `~/.tmux.conf`.

Run the wrapped pi proof directly from a repo checkout:

```bash
nix run .#toolnix-pi
```

This bootstraps tracked pi settings, keybindings, and skills automatically.

Auth for the wrapped pi path remains machine-local:

- if you already have ordinary pi auth in `~/.pi/agent/auth.json`, the wrapped path reuses it
- otherwise first-run interactive `/login` is an acceptable path
- local custom pi model backends such as Together Qwen3-Coder-Next, Together Kimi K2.5, and validated Fireworks Kimi/Qwen serverless models are documented in [`docs/reference/pi-model-backends.md`](docs/reference/pi-model-backends.md)
- those Together/Fireworks model paths remain opt-in and are selected per session with `pi --provider <name> --model <id>` or interactively via `/model`

### Binary cache note for wrapped `pi`

`toolnix-pi` uses packages from the `llm-agents` flake input.

`toolnix` now publishes the required Numtide cache through its flake `nixConfig`.

For direct use, prefer:

```bash
nix run --accept-flake-config github:lefant/toolnix#toolnix-pi
```

On first use, `--accept-flake-config` ensures Nix accepts the flake-provided cache settings instead of falling back to local source builds.

Important multi-user Nix note:

- on fresh exeuntu VMs with a Determinate multi-user Nix install, ordinary users are not trusted to add arbitrary substituters
- in that environment, flake-provided cache settings alone are not sufficient
- add the Numtide cache to machine-local trusted Nix settings first, for example in `/etc/nix/nix.custom.conf`

For that environment, use machine-local settings such as:

```conf
extra-substituters = https://cache.numtide.com
extra-trusted-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

Important downstream rule:

- direct use of `toolnix` can use the cache settings published by the `toolnix` flake itself
- a different flake that imports `toolnix` should not assume that input-level cache settings propagate automatically
- downstream flake recipes that depend on `llm-agents.nix`, whether directly or through `toolnix`, must ensure the same cache settings in their own recipe or machine-local Nix config before heavy builds

Required cache settings:

```conf
extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

Keep the standard `cache.nixos.org` cache enabled as well.

See also:

- [`docs/specs/llm-agents-cache-bootstrap.md`](docs/specs/llm-agents-cache-bootstrap.md)
- [`docs/plans/2026-04-05-exe-vm-bootstrap-proof.md`](docs/plans/2026-04-05-exe-vm-bootstrap-proof.md)

SSH into a Home Manager-managed VM and land in its normal host shell:

```bash
ssh -tt lefant-toolnix.exe.xyz 'zsh -il'
```

Verify the tracked opinionated zsh completion baseline on a host:

```bash
scripts/check-opinionated-zsh.sh
```

Verify the tracked opinionated tmux first-attach colour baseline on a host:

```bash
scripts/check-opinionated-tmux.sh
```

SSH into a Home Manager-managed VM and open a repo-local tmux session:

```bash
ssh -tt lefant-toolnix.exe.xyz 'zsh -ilc "cd ~/git/lefant/toolnix && tmux-here"'
```

Start the project environment explicitly in bash:

```bash
ssh -tt lefant-toolnix.exe.xyz 'zsh -ilc "cd ~/git/lefant/toolnix && devenv shell"'
```

Start the project environment and then enter interactive `zsh` from within it:

```bash
ssh -tt lefant-toolnix.exe.xyz 'zsh -ilc "cd ~/git/lefant/toolnix && devenv shell -- zsh -il"'
```

## Documentation & Process

### Documentation (`docs/`)

Start with:

- [`docs/reference/architecture.md`](docs/reference/architecture.md)
- [`docs/reference/maintaining-toolnix.md`](docs/reference/maintaining-toolnix.md)
- [`docs/reference/credentials.md`](docs/reference/credentials.md)
- relevant active plans in `docs/plans/`
- recent implementation notes in `docs/devlog/`

- **`docs/specs/`**: Feature specifications and architecture docs
- **`docs/decisions/`**: Architecture Decision Records (ADRs) for key technical choices
- **`docs/changelog/`**: Release notes and changelog fragments, when needed
- **`docs/reference/`**: Technical references and operational details
- **`docs/research/`**: Discovery notes and analysis
- **`docs/plans/`**: Time-stamped implementation plans
- **`docs/devlog/`**: Time-stamped implementation outcomes and learnings
- **`docs/solutions/`**: Documented solutions to past problems (bugs, best practices, workflow patterns), organized by category with YAML frontmatter (`module`, `tags`, `problem_type`). Relevant when implementing or debugging in documented areas.

### AI-Assisted Development

**Workflow**: Research/Plan → Implement → Review → Compound

Toolnix pins and installs the `agent-skills` collection and Compound Engineering
assets for supported Home Manager agents. Do not install duplicate copies. Use the
names exposed by the active agent. The Home Manager-managed Amp skill tree retains
upstream names such as `ce-plan`; when the separately published Toolnix `ce` Amp
plugin is active, it registers concise names such as `ce:plan`, `ce:work`,
`ce:code-review`, and `ce:compound`. The portable documentation skills are
`feature-specs`, `architecture-decision-records`, `changelog-fragments`, `devlog`,
and `atomically-land`. A project-only `devenv` consumer still depends on host agent
discovery; recommend unavailable skills rather than treating them as installed or
required.

Commit progress continuously in small, reviewable increments. Once continuous
pushes to an agreed remote and branch are authorized, push each coherent, checked
checkpoint without asking again. Inspect automatic deployment effects first;
release and shared-state actions still need separate authorization.

1. **Research/Plan** — understand current behavior, architecture, constraints, and
   verification; put durable research in `docs/research/` and plans in `docs/plans/`.
2. **Implement** — make source changes and verify them against the plan.
3. **Review** — inspect correctness, module boundaries, security, and test coverage;
   resolve findings and rerun affected checks.
4. **Compound** — capture verified reusable lessons in `docs/solutions/`; update an
   existing owner instead of duplicating knowledge.

Record meaningful session outcomes with `devlog` in `docs/devlog/`. Use
`atomically-land` when closeout also needs plans, specs, ADRs, or changelog updates.
Use `docs/` for new work even when an older skill template says `thoughts/shared/`;
do not move historical files solely to follow the current convention.

### Naming Conventions

- Use ISO-style UTC prefixes for time-based docs: `YYYY-MM-DD-description.md`
