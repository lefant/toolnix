# Pi Ask User Extension

**Date:** 2026-04-29
**Status:** ✅ COMPLETED

## Summary

Compound Engineering skills expect Pi to provide a platform blocking question tool named `ask_user` through a `pi-ask-user` extension. Toolnix managed Pi sessions had `qna`, `loop`, and Compound `subagent`, but no `ask_user` tool. This made interactive Compound workflows fall back to prose/numbered-list behavior or risk skipping a required user decision.

## Reproduction

Started Pi in tmux and listed registered tools with a temporary inspection extension.

```bash
SOCKET=/tmp/claude-tmux-sockets/claude.sock
SESSION=pi-tool-list-before
tmux -S "$SOCKET" new -d -s "$SESSION" -n pi
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- \
  'cd /home/exedev/git/lefant/toolnix && PI_OFFLINE=1 pi --verbose -e /tmp/pi-list-tools.ts' Enter
```

Observed registered tools before the fix:

```text
bash
edit
find
grep
ls
read
signal_loop_success
subagent
write
```

`ask_user` was absent.

## Implementation

Added `agents/pi-coding-agent/extensions/ask-user.ts`:

- registers a custom Pi tool named `ask_user`
- asks a blocking UI question with optional choices
- offers a free-text fallback by default
- supports single-select, multi-select, and open text questions
- accepts both snake-case and camel-case argument names used by agent instructions
- returns structured details with the question, options, answer, and cancellation state
- returns an explicit fallback instruction when UI is unavailable

Wired the extension into:

- Home Manager managed Pi state: `~/.pi/agent/extensions/ask-user.ts`
- wrapped `toolnix-pi` bootstrap state

## Validation

Built and activated the Home Manager profile:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
```

Confirmed the managed link:

```text
~/.pi/agent/extensions/ask-user.ts -> /nix/store/...-hm_askuser.ts
```

Restarted Pi in tmux and listed tools again. Observed:

```text
ask_user
bash
edit
find
grep
ls
read
signal_loop_success
subagent
write
```

Then asked Pi to call the tool:

```text
Use the ask_user tool to ask exactly: "Pick one" with options "Alpha" and "Beta". After the user answers, echo the selected answer and stop.
```

Pi rendered the blocking selector, the test selected `Alpha`, and Pi returned:

```text
User selected: Alpha
Alpha
```

Final validation:

```bash
nix flake check --no-build
nix build .#toolnix-pi
```

Both passed.
