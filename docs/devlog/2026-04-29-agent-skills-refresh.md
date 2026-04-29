# Agent Skills Refresh

**Date:** 2026-04-29
**Status:** ✅ COMPLETED

## Summary

Updated Toolnix to reference the latest `lefant/agent-skills` revision. This brings in the refreshed vendor skills and the latest skill-layout cleanup work from `agent-skills`.

## Input update

- Previous `agent-skills`: `1682667453c5c287cef8a0d704f501d57f0d2c2e`
- New `agent-skills`: `77af04cafeb25b20092371052322cb78e92d2097`

Upstream changes included:

```text
b6d0c15 refactor(vendor): flatten obsidian skills
b5daff8 test(vendor): check skill layout
2dbda05 docs(devlog): record vendor layout check
42bca51 chore(vendor): refresh chrome-devtools-cli
4c29bbc chore(vendor): refresh caveman-compress
38a1283 chore(vendor): refresh skill-creator license
fc91a05 chore(vendor): refresh zfc
ec1f1b8 chore(vendor): refresh remotion best practices
cb5382a chore(vendor): refresh agent-browser
70fb7d0 chore(vendor): refresh react best practices
03fbdbf chore(vendor): refresh ai-sdk errors
77af04c docs: import agent skill best practices
```

## Validation

Commands run:

```bash
nix flake lock --update-input agent-skills
nix flake check --no-build
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
```

Post-activation checks confirmed the updated managed skill trees are linked for the current host:

```text
~/.agents/skills -> toolnix-managed-skills
~/.claude/skills -> toolnix-managed-claude-skills-with-compound-engineering
~/.config/opencode/skills -> toolnix-managed-opencode-skills-with-compound-engineering
~/.pi/agent/skills -> toolnix-managed-skills-with-compound-engineering
~/.codex/skills/compound-engineering -> compound-engineering-codex-assets/skills/compound-engineering
```

## Notes

Compound Engineering remains default-enabled for Toolnix Home Manager hosts. Target-specific Compound fanout remains separated from the refreshed portable `agent-skills` baseline.
