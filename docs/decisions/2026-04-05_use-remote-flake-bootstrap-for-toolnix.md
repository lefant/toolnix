# Use remote flake consumption as the default toolnix bootstrap path

## Date

2026-04-05

## Status

accepted

## Context

Fresh-machine bootstrap should not require a mutable local checkout of `toolnix` on the target system before Nix can take over.

`toolnix` already publishes stable flake outputs that are suitable for remote consumption, including:

- wrapped-tool proofs such as `toolnix-pi`
- `homeManagerModules.default`
- `devenvModules.default`

This allows a fresh machine to fetch and evaluate `toolnix` directly from a public GitHub flake reference instead of relying on imperative git clone steps.

That remote-flake path is a better bootstrap default than a working-copy clone because it is:

- public and reproducible
- visible in the flake dependency graph
- closer to the declarative target state
- easier to use from systems that have no preexisting control-host relationship

## Decision

`toolnix` uses remote flake consumption as the default bootstrap path for fresh environments.

That means:

- bootstrap flows should prefer public flake refs such as `github:lefant/toolnix`
- bootstrap docs should treat exported flake outputs as the primary stable interface
- local working-copy clones of `toolnix` are for active development, not the default bootstrap requirement for target systems

## Consequences

Fresh-machine bootstrap can remain public, declarative, and independent of preexisting repo checkouts on target hosts.

This makes exported flake interfaces more important and increases the need to document which `toolnix` surfaces are stable bootstrap interfaces.

It also means raw file-path consumption from the repo should be treated more carefully than flake-output consumption, because not every internal source path is a stable published interface.
