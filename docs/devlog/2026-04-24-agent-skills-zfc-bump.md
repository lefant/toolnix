## Summary

Bumped `toolnix` to the latest `github:lefant/agent-skills` revision after adding the vendored `zfc` skill there from `lambdamechanic/skills`.

The updated shared skill bundle now picks up:

- `vendor/lambdamechanic/zfc`
- the added upstream reference to Steve Yegge's Zero Framework Cognition article

## What changed

Changed:

- `flake.lock`
- `devenv.lock`
- `docs/devlog/2026-04-24-agent-skills-zfc-bump.md`

## Why

`toolnix` consumes the shared `lefant/agent-skills` bundle through its flake input.

After landing the upstream ZFC skill in `agent-skills`, `toolnix` needed an input bump so the managed skill tree exposed by this repo includes the new vendored skill for wrapped agent environments.
