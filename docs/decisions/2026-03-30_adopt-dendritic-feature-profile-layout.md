# Adopt dendritic feature/profile layout for toolnix internals

## Date

2026-03-30

## Status

accepted

## Context

After the flake-parts migration, `toolnix` still had a transitional structure. The repo already thought in cross-cutting slices:

- required baseline
- agent baseline
- opinionated shell
- agent browser
- host control

But profile glue still imported shared helpers directly, which kept architecture knowledge scattered and made the internal structure harder to grow.

## Decision

`toolnix` uses a dendritic-style internal structure:

- flake-parts feature modules publish the A/R/O/H slices into merged registries
- flake-parts profile modules assemble Home Manager and `devenv` from those registries
- public module paths remain stable through compatibility wrappers

## Consequences

The repo now matches its architectural model more closely, and future internal changes can usually land as feature-module changes rather than profile rewrites.

This makes the internals more abstract and slightly harder to approach casually, but it reduces hidden coupling and avoids another structural reset for the current toolnix scope.
