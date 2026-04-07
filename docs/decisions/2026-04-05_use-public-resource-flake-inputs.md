# Use public resource flake inputs for shared modular assets

## Date

2026-04-05

## Status

accepted

## Context

`toolnix` needs a way to consume modular resources that are shared publicly across environments without requiring imperative cloning or host-local repo management on target systems.

`agent-skills` already demonstrates a strong pattern for this:

- the resource lives in its own public repo
- `toolnix` consumes it as a flake input
- Nix fetches it into the store/cache path
- `toolnix` derives managed runtime state from that fetched source
- target machines do not need ordinary working-copy clones of the source repo

This is a better fit for shared public resources than ad hoc bootstrap cloning because it keeps ownership declarative and makes the dependency visible in the flake graph.

## Decision

`toolnix` uses public flake inputs as the default pattern for modular shared resources such as `agent-skills`.

When a resource is suitable for public sharing:

- it should live in its own public repo when that improves modularity
- `toolnix` should consume it through a flake input rather than by imperative clone steps on the target machine
- `toolnix` should derive managed runtime artifacts from the fetched input and wire those artifacts declaratively into host or shell state

## Consequences

Shared modular resources can now be published, versioned, cached, and consumed through the normal Nix dependency graph.

This reduces bootstrap complexity on target systems and avoids hidden host-local clone requirements.

It does add another repo/input boundary and makes cache/documentation discipline more important, but that tradeoff is acceptable for public reusable assets in the current `toolnix` architecture.
