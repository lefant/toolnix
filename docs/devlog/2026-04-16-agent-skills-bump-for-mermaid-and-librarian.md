## Summary

Bumped `toolnix` to the latest `github:lefant/agent-skills` revision after adding new vendored skills there from `mitsuhiko/agent-stuff`.

The updated shared skill bundle now includes:

- `vendor/mitsuhiko/mermaid`
- `vendor/mitsuhiko/librarian`

It also includes the local `mermaid-diagrams` guidance update that points at the vendored Mermaid validator helper.

## What changed

Changed:

- `flake.lock`
- `docs/research/2026-04-16-agent-stuff-shortlist-follow-up.md`
- `docs/devlog/2026-04-16-agent-skills-bump-for-mermaid-and-librarian.md`

## Why

`toolnix` consumes the shared `lefant/agent-skills` bundle through its flake input.

After landing the new vendored skills upstream, `toolnix` needed an input bump so the managed skill tree exposed by this repo picks them up.

The accompanying research note was also updated to record the decision that `pi-share-hf` is out of scope for current adoption.
