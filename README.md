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
