# Compound Engineering plugin refresh

**Date:** 2026-05-01
**Status:** ✅ COMPLETED

## Summary

Updated Toolnix's pinned `compound-engineering-plugin` input and confirmed the new `/ce-strategy` skill is available across the managed target fanout after Home Manager activation.

## Input update

Updated flake input:

```text
compound-engineering-plugin
```

Revision changed:

```text
e5b397c9d1883354f03e338dd00f98be3da39f9f
→ ae408721cdfd739688a397e11deca4f4b7ec9eae
```

Nix reported the upstream date changed from 2026-04-29 to 2026-05-01.

## Validation

Evaluated and built the refresh:

```bash
nix flake check --no-build
nix build \
  .#checks.x86_64-linux.compound-engineering-assets \
  .#checks.x86_64-linux.compound-engineering-skills-opt-out \
  .#homeConfigurations.lefant-toolnix.activationPackage
./result-2/activate
```

All checks passed and the Home Manager generation activated successfully.

## ce-strategy availability

Confirmed the upstream source contains the new skill:

```text
/nix/store/9jhz0v5wvgz8ipj7kw8xm3vlqc3bnkxl-source/plugins/compound-engineering/skills/ce-strategy/SKILL.md
```

Confirmed installed target paths after activation:

```text
~/.pi/agent/skills/ce-strategy/SKILL.md
~/.claude/skills/ce-strategy/SKILL.md
~/.config/opencode/skills/ce-strategy/SKILL.md
~/.codex/skills/compound-engineering/ce-strategy/SKILL.md
```

Started a fresh Pi session in tmux to confirm runtime discovery:

```bash
SOCKET=/tmp/claude-tmux-sockets/claude.sock
SESSION=pi-ce-strategy-check

tmux -S "$SOCKET" new -d -s "$SESSION" -n pi
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- \
  'cd /home/exedev/git/lefant/toolnix && PI_OFFLINE=1 pi --verbose' Enter
```

Captured startup output showed:

```text
[Skills]
  ~/.pi/agent/skills/ce-strategy/SKILL.md

[Extensions]
  ~/.pi/agent/extensions/ask-user.ts
```

The `ask_user` extension is important because `ce-strategy` uses the Compound blocking-question interaction pattern and explicitly names Pi's `ask_user` tool.

## Result

`/ce-strategy` is available in Pi and in the declarative target fanout for Claude Code, OpenCode, and Codex CLI.
