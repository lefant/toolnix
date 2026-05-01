# Disable Toolnix-managed OpenClaw skills root

**Date:** 2026-05-01
**Status:** ✅ COMPLETED

## Summary

Disabled Home Manager provisioning of `~/.openclaw/skills` because the current Toolnix managed skill tree is a link farm whose child entries resolve outside the managed root. OpenClaw intentionally rejects those child symlinks as `symlink-escape`, so the provisioned root exists but the skills are skipped.

## Problem

On `lefant-openclaw-bottle`, OpenClaw was configured to scan the Toolnix-managed skill root:

```text
~/.openclaw/skills -> /nix/store/...-home-manager-files/.openclaw/skills
```

The root ultimately resolved to a Toolnix managed skill tree, but individual skills inside it were symlinks to other Nix store paths. Example shape:

```text
rootRealPath       = /nix/store/...-toolnix-managed-skills-with-compound-engineering
candidateRealPath  = /nix/store/...-source/lefant/exa
```

OpenClaw resolves both paths and requires every candidate skill to remain inside the configured root realpath. Because the child symlink target was outside the root, OpenClaw skipped the skill with `reason=symlink-escape`.

This is expected OpenClaw safety behavior and a Toolnix packaging/layout mismatch, not bad skill content.

## Change

Removed the Home Manager file entry for:

```text
~/.openclaw/skills
```

from `internal/profiles/home-manager/core.nix`.

Updated `docs/reference/architecture.md` to make the OpenClaw boundary explicit:

- `~/.openclaw/openclaw.json` is runtime-owned mutable state
- `~/.openclaw/skills` is also not Home Manager-managed for now
- OpenClaw should use runtime config such as `skills.load.extraDirs` pointed at a local `lefant/agent-skills` checkout until Toolnix can provide an OpenClaw-safe materialized skill tree

## Operational workaround

For current OpenClaw hosts, use the runtime-owned OpenClaw config to point at a local checkout:

```json5
{
  skills: {
    load: {
      extraDirs: ["/home/exedev/git/lefant/agent-skills/lefant"]
    }
  }
}
```

This loads Toolnix-adjacent shared skills through OpenClaw's extra-dir mechanism instead of the broken Nix link-farm root. The host must keep the checkout present and updated separately.

## Future fix

A future Toolnix-managed OpenClaw path should build a real/materialized directory tree in one Nix output, for example:

```text
/nix/store/<hash>-toolnix-openclaw-skills/
  exa/
    SKILL.md
    scripts/...
  github-access/
    SKILL.md
```

Then `~/.openclaw/skills` could point at that one output without child symlinks escaping the root realpath.
