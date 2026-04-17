## Summary

Bumped `toolnix` to the latest `github:lefant/agent-skills` revision after adding the vendored `pdf` skill from `anthropics/skills` there.

The updated shared skill bundle now includes:

- `vendor/anthropics/pdf`

That skill adds shared guidance and helper scripts for PDF extraction, merging, splitting, OCR, and form-filling workflows.

## What changed

Changed:

- `flake.lock`
- `docs/devlog/2026-04-17-agent-skills-pdf-bump.md`

## Why

`toolnix` consumes the shared `lefant/agent-skills` bundle through its flake input.

After landing the new vendored Anthropic PDF skill upstream, `toolnix` needed an input bump so the managed skill tree exposed by this repo picks it up for downstream agent environments.
