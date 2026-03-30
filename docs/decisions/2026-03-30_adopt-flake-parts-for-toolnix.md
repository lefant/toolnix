# Adopt flake-parts for toolnix

## Date

2026-03-30

## Status

accepted

## Context

`toolnix` had grown into a public Nix repo with multiple exported surfaces:

- Home Manager host configuration
- Home Manager module export
- `devenv` module export
- shared flake input export

Manual output wiring in `flake.nix` was becoming the architectural bottleneck. Internal refactors required repeated ad hoc wiring, and feature slices could not evolve toward a more modular composition model cleanly.

## Decision

`toolnix` uses `flake-parts` as its top-level flake construction system.

Public outputs remain stable, but their internal construction is now delegated to flake-parts modules and flake-parts-owned profile composition.

## Consequences

Internal output composition is now easier to extend and reason about.

This raises the abstraction level of the repo and requires more discipline around flake module composition, but it removes the previous manual-wiring bottleneck and enables the feature/profile architecture adopted later the same day.
