# toolnix

Public Nix-first development environment and host-profile repo.

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

## Documentation & Process

### Documentation (`docs/`)

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
