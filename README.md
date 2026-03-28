# toolnix

Public Nix-first development environment and host-profile repo.

## Start Here

- Architecture reference: [`docs/reference/architecture.md`](docs/reference/architecture.md)
- Setup-hook migration plan: [`docs/plans/2026-03-28-remove-imperative-setup-hook.md`](docs/plans/2026-03-28-remove-imperative-setup-hook.md)

## Scope

`toolnix` publishes the shared Nix layer currently prototyped in `toolbox`:

- shared `A/R/O/H` baselines
- Home Manager host profiles
- `devenv` integration for project consumers
- tracked agent config and shared skills

The intended consumption modes are:

- read-only GitHub flake refs for projects and hosts
- local `path:` overrides for active development

## First goals

- support self-hosted development on `lefant-toolnix`
- support a minimal project consumer proof on `asimov-hex`
- remove sibling-path and subtree assumptions from the published interface

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

Optional `agent-browser` support for project consumers:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.agentBrowser.enable = true;
}
```

### Agent-Browser First Run

On a newly enabled host or project:

- the `agent-browser` wrapper is available on `PATH` immediately
- the real CLI is installed lazily on first `agent-browser` invocation
- the browser runtime still needs a one-time install step

Minimal first-run flow:

```bash
agent-browser --version
agent-browser install
```

After that, ordinary usage works without Docker:

```bash
agent-browser open https://example.com
agent-browser wait --load networkidle
agent-browser get title
agent-browser close
```

Host-local state paths used by the opt-in integration:

- npm prefix: `~/.local/share/toolnix/agent-browser/npm-prefix`
- npm cache: `~/.cache/toolnix-agent-browser/npm`
- browser runtime state: `~/.agent-browser`

## Common Commands

SSH into a Home Manager-managed VM and land in its normal host shell:

```bash
ssh -tt lefant-toolnix.exe.xyz 'zsh -il'
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
- relevant active plans in `docs/plans/`
- recent implementation notes in `docs/devlog/`


- **`docs/specs/`**: Feature specifications and architecture docs
- **`docs/decisions/`**: Architecture Decision Records (ADRs) for key technical choices
- **`docs/reference/`**: Technical references and operational details
- **`docs/research/`**: Discovery notes and analysis
- **`docs/plans/`**: Time-stamped implementation plans
- **`docs/devlog/`**: Time-stamped implementation outcomes and learnings

### AI-Assisted Development

**Workflow**: Research -> Plan -> Implement -> Devlog

Commit progress continuously in small, reviewable increments while work is underway.

1. **Research** — document current behavior, constraints, and dependencies
2. **Plan** — define implementation strategy and sequencing -> `docs/plans/`
3. **Implement** — execute changes and verification
4. **Devlog** — record outcomes, caveats, and follow-ups -> `docs/devlog/`

### Naming Conventions

- Use ISO-style UTC prefixes for time-based docs: `YYYY-MM-DD-description.md`
