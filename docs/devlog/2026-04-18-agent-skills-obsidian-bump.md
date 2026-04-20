## Summary

Bumped `toolnix` to the latest `github:lefant/agent-skills` revision after syncing the vendored `kepano/obsidian-skills` subtree there.

The updated shared skill bundle now picks up:

- `vendor/kepano/obsidian-skills/skills/obsidian-cli`
- `vendor/kepano/obsidian-skills/skills/defuddle`
- refreshed upstream content for `obsidian-markdown`, `obsidian-bases`, and `json-canvas`
- the new upstream reference files those skills now link to

## What changed

Changed:

- `flake.lock`
- `devenv.lock`
- `docs/devlog/2026-04-18-agent-skills-obsidian-bump.md`

## Why

`toolnix` consumes the shared `lefant/agent-skills` bundle through its flake input.

After landing the upstream Obsidian subtree sync in `agent-skills`, `toolnix` needed an input bump so the managed skill tree exposed by this repo includes the new Obsidian CLI and Defuddle skills plus the updated Obsidian reference content.
