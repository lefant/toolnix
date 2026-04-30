# Pi ask_user tmux validation

**Date:** 2026-04-30
**Status:** ✅ COMPLETED

## Summary

Ran a fresh tmux validation of the managed Pi `ask_user` extension after the hardening pass. The validation confirmed that a new Toolnix-managed Pi session loads the extension, registers the `ask_user` tool, renders a blocking selector, accepts object-shaped options with numeric values, and returns the selected answer to the model.

## Environment

- Repo: `/home/exedev/git/lefant/toolnix`
- Branch: `main`
- Tmux socket: `/tmp/claude-tmux-sockets/claude.sock`
- Tmux session: `pi-ask-user-validation`
- Managed extension link:

```text
~/.pi/agent/extensions/ask-user.ts -> /nix/store/p23v9q2hi2fwfzxfvxbh80sk8850i7h6-hm_askuser.ts
```

## Tool registration check

Started Pi in a fresh tmux session with a temporary inspection extension that writes registered tool names to `/tmp/pi-tools-validation.txt`:

```bash
SOCKET=/tmp/claude-tmux-sockets/claude.sock
SESSION=pi-ask-user-validation

cat > /tmp/pi-list-tools-validation.ts <<'EOF'
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { writeFileSync } from "node:fs";
export default function (pi: ExtensionAPI) {
  pi.on("session_start", async () => {
    writeFileSync("/tmp/pi-tools-validation.txt", pi.getAllTools().map((tool) => tool.name).sort().join("\n") + "\n");
  });
}
EOF

tmux -S "$SOCKET" new -d -s "$SESSION" -n pi
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- \
  'cd /home/exedev/git/lefant/toolnix && PI_OFFLINE=1 pi --verbose -e /tmp/pi-list-tools-validation.ts' Enter
```

Observed registered tools:

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

Pi startup also listed the managed extension:

```text
[Extensions]
  user
    ~/.pi/agent/extensions/answer.ts
    ~/.pi/agent/extensions/ask-user.ts
    ~/.pi/agent/extensions/exe-dev
    ~/.pi/agent/extensions/loop.ts
    ~/.pi/agent/extensions/qna.ts
    ~/.pi/agent/extensions/subagent
  path
    /tmp/pi-list-tools-validation.ts
```

## Model-backed selector check

Sent a prompt that forced a real `ask_user` tool call and used object-shaped options with numeric `value` fields. This exercises the option-coercion hardening added after the first review.

```text
Call the ask_user tool exactly once. Use question: "Validation choice".
Use options as objects: {"label":"Proceed","value":1} and
{"label":"Stop","value":2}. Set allow_free_text to false. After the user
selects, echo only the selected answer.
```

Pi rendered the blocking selector:

```text
ask_user

Validation choice

→ Proceed
  Stop

↑↓ navigate  enter select  escape/ctrl+c cancel
```

Selected `Stop` with tmux key input:

```bash
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 Down Enter
```

Observed result:

```text
ask_user
User selected: Stop

Stop
```

## Build validation

After the tmux run, built the wrapped Pi package to confirm the wrapper path still evaluates and builds with the managed `ask-user.ts` extension included:

```bash
nix build .#toolnix-pi
```

Build completed successfully.

## Findings

- `ask_user` is registered in a fresh Toolnix-managed Pi session.
- The managed extension path is loaded from Home Manager state, not an ad hoc local file.
- Model-backed tool invocation works in tmux.
- Blocking selection UI renders correctly.
- Object options with numeric `value` fields no longer crash option normalization.
- `allow_free_text: false` single-select behavior correctly omits the custom-answer choice from the selector.
- Wrapped `toolnix-pi` still builds after the extension hardening.

## Follow-ups

- Optional: add an automated check that starts Pi with a tiny inspection extension and asserts `ask_user` is present. This would catch future regressions in managed Pi extension wiring, but it may be too heavyweight for ordinary flake checks if Pi startup remains interactive.
