---
date: 2026-04-28
status: ✅ COMPLETED
related_issues: []
---

# Implementation Log - 2026-04-28

**Implementation**: Verified that the repo-managed Pi auto-compaction defaults are installed on this host and that Pi actually performs automatic compaction under incremental context growth.

## Summary

This session found the tracked Pi settings template in `toolnix`, confirmed that the active Home Manager-managed runtime config points at the rendered Nix-store copy of that template, and tested Pi in an isolated tmux session with a low-thinking model. The verification used `openai-codex/gpt-5.3-codex-spark` because its 128K context window makes the configured `reserveTokens = 100000` threshold easy to hit quickly. Incremental prompt spam triggered automatic compaction with `reason = "threshold"` after the second turn, proving that the aggressive compaction settings are not just present in JSON but are actively used by Pi at runtime.

No production config changes were required. The only repository change from this session is this devlog.

## Plan vs Reality

**What was planned:**

- [x] Find the Pi config in `toolnix` that controls automatic compaction.
- [x] Confirm whether the active host config uses that tracked template.
- [x] Start Pi under tmux with a low-thinking model.
- [x] Incrementally spam context until automatic compaction triggers.
- [x] Capture enough evidence to distinguish proactive threshold compaction from overflow recovery.

**What was actually implemented:**

- [x] Located `agents/pi-coding-agent/templates/settings.json` as the tracked Pi settings source.
- [x] Confirmed Home Manager wires it to `~/.pi/agent/settings.json` through `internal/profiles/home-manager/core.nix`.
- [x] Confirmed wrapped `toolnix-pi` also uses the same template through `flake-parts/wrapped-tools.nix`.
- [x] Verified the active `~/.pi/agent/settings.json` resolves to a Nix-store Home Manager output.
- [x] Ran a smoke test against `openai-codex/gpt-5.5` to confirm Pi auth/model access worked.
- [x] Ran an oversized first-turn test that triggered overflow compaction.
- [x] Ran a second, incremental threshold test that triggered proactive auto-compaction after two turns.
- [x] Preserved the test scripts and logs under `/tmp/pi-compact-test` for short-term inspection.

## Config Found

Tracked source:

- `agents/pi-coding-agent/templates/settings.json`

Current tracked settings:

```json
{
  "defaultProvider": "openai-codex",
  "defaultModel": "gpt-5.5",
  "defaultThinkingLevel": "high",
  "compaction": {
    "enabled": true,
    "reserveTokens": 100000,
    "keepRecentTokens": 20000
  }
}
```

Home Manager wiring:

- `internal/profiles/home-manager/core.nix`
- relevant stanza:
  - `home.file.".pi/agent/settings.json".source = ../../../agents/pi-coding-agent/templates/settings.json;`
  - `force = true;`

Wrapped Pi wiring:

- `flake-parts/wrapped-tools.nix`
- relevant values:
  - `piSettings = ../agents/pi-coding-agent/templates/settings.json;`
  - `toolnix-pi` symlinks that file into `$PI_CODING_AGENT_DIR/settings.json` when missing.

Active host runtime path:

```bash
readlink -f ~/.pi/agent/settings.json
```

Result:

```text
/nix/store/5bzaw2fv8fmcajyiqfdmdqw92sl5z5j2-hm_settings.json
```

Active runtime settings:

```bash
jq . ~/.pi/agent/settings.json
```

Relevant result:

```json
{
  "defaultProvider": "openai-codex",
  "defaultModel": "gpt-5.5",
  "defaultThinkingLevel": "high",
  "compaction": {
    "enabled": true,
    "reserveTokens": 100000,
    "keepRecentTokens": 20000
  }
}
```

## Compaction Semantics Confirmed

Pi upstream docs define the proactive auto-compaction trigger as:

```text
contextTokens > contextWindow - reserveTokens
```

With `reserveTokens = 100000`, this is not a fixed percentage by itself. It depends on the selected model context window:

| Model shape | Context window | Trigger point | Approximate percent |
|-------------|----------------|---------------|---------------------|
| `openai-codex/gpt-5.5` | 272K | 172K | 63% |
| `openai-codex/gpt-5.3-codex-spark` | 128K | 28K | 22% |
| Hypothetical 200K model | 200K | 100K | 50% |

The tested low-thinking model was:

```text
openai-codex/gpt-5.3-codex-spark
context: 128K
thinking: yes
images: no
```

That model was chosen because it makes the configured threshold easy to hit without wasting a full 172K-token prompt on the default 272K model.

## Verification Commands

Model/config discovery used:

```bash
rg -n "compact|compaction|auto.?compact|context" \
  . /home/exedev/.pi/agent/config.json /home/exedev/.pi/agent/settings.json 2>/dev/null || true

jq . agents/pi-coding-agent/templates/settings.json
jq . ~/.pi/agent/settings.json
readlink -f ~/.pi/agent/settings.json

rg -n "piSettings|settings.json|compaction|reserveTokens|keepRecentTokens|\.pi/agent/settings.json" \
  agents/pi-coding-agent/templates/settings.json \
  flake-parts/wrapped-tools.nix \
  internal/profiles/home-manager/core.nix \
  docs/devlog/2026-04-24-pi-aggressive-compaction-defaults.md
```

Pi docs checked from the installed package:

```bash
rg -n "compaction|reserveTokens|keepRecentTokens|contextWindow|auto" \
  /nix/store/q7hbgpxj10l09kffc5dpypkwag3zpdq7-pi-0.70.2/lib/node_modules/@mariozechner/pi-coding-agent/README.md \
  /nix/store/q7hbgpxj10l09kffc5dpypkwag3zpdq7-pi-0.70.2/lib/node_modules/@mariozechner/pi-coding-agent/docs
```

Smoke test used:

```bash
mkdir -p /tmp/pi-compact-test
printf 'ping, answer one word only: ok' >/tmp/pi-compact-test/prompt.txt

timeout 45s pi --mode json \
  --session-dir /tmp/pi-compact-test/sessions \
  --provider openai-codex \
  --model gpt-5.5 \
  --thinking low \
  --no-extensions \
  --no-skills \
  --no-prompt-templates \
  --no-themes \
  --no-context-files \
  "$(cat /tmp/pi-compact-test/prompt.txt)" \
  2>&1 | tee /tmp/pi-compact-test/smoke.jsonl | tail -50
```

Smoke result confirmed a valid assistant response from `gpt-5.5` with real usage accounting:

```text
assistant usage input=1106 output=5 total=1111 model=gpt-5.5
```

## tmux Test Setup

The tests ran in isolated tmux sessions under the agent socket:

```bash
SOCKET=/tmp/claude-tmux-sockets/claude.sock
```

Oversized overflow test session:

```bash
tmux -S /tmp/claude-tmux-sockets/claude.sock attach -t pi-compact-test
```

Incremental threshold test session:

```bash
tmux -S /tmp/claude-tmux-sockets/claude.sock attach -t pi-compact-threshold
```

Capture output:

```bash
tmux -S /tmp/claude-tmux-sockets/claude.sock capture-pane -p -J -t pi-compact-threshold:0.0 -S -200
```

The threshold test script was written to:

- create a fresh session directory under `/tmp/pi-compact-test/threshold-<timestamp>`
- use `--mode json` so compaction events are machine-readable
- use `--continue` after the first turn
- disable extensions, skills, prompt templates, themes, and context files to keep the test focused
- generate repeated context payloads incrementally
- stop when a persisted session `compaction` entry appears

Script path:

- `/tmp/pi-compact-test/run-threshold.sh`

## Test Results

### Overflow recovery test

The first stress test used a single oversized prompt. It proved automatic compaction can recover from context overflow, but it was not sufficient by itself to prove the proactive threshold behavior.

Log root:

- `/tmp/pi-compact-test/run-20260428T141422Z`

Observed result:

```text
=== turn 1 payload=/tmp/pi-compact-test/run-20260428T141422Z/payloads/turn-1.txt bytes=804097 words=108013 ===
pi_exit=0
event summary:
assistant usage input=0 output=0 total=0 model=gpt-5.3-codex-spark
compaction_start reason=overflow
session=/tmp/pi-compact-test/run-20260428T141422Z/sessions/2026-04-28T14-14-24-171Z_019dd470-eeab-7561-a2c3-036e3b861ae8.jsonl compaction_entries=1
```

Persisted compaction entry summary:

```json
{
  "id": "7f8591e6",
  "firstKeptEntryId": "062254ca",
  "tokensBefore": 201052,
  "summaryChars": 795,
  "fromHook": false,
  "details": {
    "readFiles": [],
    "modifiedFiles": []
  }
}
```

Conclusion: overflow compaction works, but a smaller incremental test was needed.

### Proactive threshold test

The second test incrementally grew the session context using `openai-codex/gpt-5.3-codex-spark` with `--thinking low`.

Log root:

- `/tmp/pi-compact-test/threshold-20260428T141458Z`

Session file:

- `/tmp/pi-compact-test/threshold-20260428T141458Z/sessions/2026-04-28T14-14-59-358Z_019dd471-781d-767a-b309-89ce10d284dc.jsonl`

Turn 1:

```text
=== turn 1 payload=/tmp/pi-compact-test/threshold-20260428T141458Z/payloads/turn-1.txt bytes=64097 words=8013 ===
pi_exit=0
event summary:
assistant usage input=25562 output=36 total=25598 model=gpt-5.3-codex-spark
session=/tmp/pi-compact-test/threshold-20260428T141458Z/sessions/2026-04-28T14-14-59-358Z_019dd471-781d-767a-b309-89ce10d284dc.jsonl compaction_entries=0
```

Turn 2:

```text
=== turn 2 payload=/tmp/pi-compact-test/threshold-20260428T141458Z/payloads/turn-2.txt bytes=64097 words=8013 ===
pi_exit=0
event summary:
assistant usage input=24567 output=53 total=50092 model=gpt-5.3-codex-spark
compaction_start reason=threshold
session=/tmp/pi-compact-test/threshold-20260428T141458Z/sessions/2026-04-28T14-14-59-358Z_019dd471-781d-767a-b309-89ce10d284dc.jsonl compaction_entries=1
```

Persisted compaction entry:

```json
{
  "type": "compaction",
  "id": "7c705641",
  "parentId": "a74f2bb1",
  "timestamp": "2026-04-28T14:15:06.138Z",
  "summary": "## Goal\n- (none provided; no conversation content to infer any user objectives)\n\n## Constraints & Preferences\n- (none mentioned)\n\n## Progress\n### Done\n- [ ] No tasks or changes were provided in the conversation.\n\n### In Progress\n- [ ] No active work is currently in progress.\n\n### Blocked\n- No information yet available to proceed.\n\n## Key Decisions\n- **No-op**: There are no decisions yet because the conversation contains no prompts, requests, or code changes.\n\n## Next Steps\n1. Obtain the user’s actual request/task details to establish goals and constraints.\n2. Identify relevant files/functions/code context from the user.\n3. Begin implementation or analysis based on the new requirements.\n\n## Critical Context\n- (none)",
  "firstKeptEntryId": "ac931fb5",
  "tokensBefore": 50092,
  "details": {
    "readFiles": [],
    "modifiedFiles": []
  },
  "fromHook": false
}
```

JSON event stream check:

```bash
RUN=/tmp/pi-compact-test/threshold-20260428T141458Z
jq -c 'select(.type|test("compaction"))' "$RUN/turn-2.jsonl"
```

Output:

```json
{"type":"compaction_start","reason":"threshold"}
```

Assistant usage across the threshold test:

```bash
jq -r 'select(.type=="message_end" and .message.role=="assistant") | [.message.usage.input,.message.usage.output,.message.usage.totalTokens,.message.model] | @tsv' \
  "$RUN/turn-1.jsonl" "$RUN/turn-2.jsonl"
```

Output:

```text
25562	36	25598	gpt-5.3-codex-spark
24567	53	50092	gpt-5.3-codex-spark
```

Conclusion: proactive automatic compaction is working. The threshold event occurred after the running context estimate exceeded the configured threshold for the selected model.

## Challenges & Solutions

**Challenge: `reserveTokens = 100000` does not equal a universal 50% trigger.**

- The trigger formula subtracts `reserveTokens` from the selected model context window.
- On the default 272K `gpt-5.5` model, the trigger is around 172K tokens, or about 63%.
- On a 200K model, the same setting would trigger around 50%.
- On the tested 128K model, the same setting triggers around 28K tokens, or about 22%.

**Solution:** Use `openai-codex/gpt-5.3-codex-spark`, a lower-context model available from the same provider, to reach the configured threshold quickly and cheaply.

**Challenge: A single huge prompt initially triggered `reason = "overflow"`, not `reason = "threshold"`.**

- Overflow compaction is valid auto-compaction, but it does not prove proactive threshold compaction.

**Solution:** Create a second test script with smaller per-turn payloads and `--continue` so context grows incrementally across turns. This produced `compaction_start reason=threshold` on turn 2.

**Challenge: Interactive Pi output is not ideal for deterministic verification.**

- The TUI is good for manual use, but event capture is easier from JSON mode.

**Solution:** Run Pi in `--mode json` inside tmux and inspect both JSON events and persisted session JSONL entries.

## Learnings

- `toolnix` currently centralizes Pi runtime defaults in `agents/pi-coding-agent/templates/settings.json`.
- Both Home Manager and the wrapped `toolnix-pi` path source the same Pi settings template.
- The active host has the Home Manager-managed settings file installed as a Nix-store rendered JSON file.
- Pi's proactive compaction threshold is absolute-token based, not percentage based.
- `compaction.reserveTokens = 100000` is a strong early-compaction default for most long-context coding models, but its effective percentage varies by model.
- `--mode json` exposes `compaction_start` and `compaction_end` events; the persisted session JSONL is the best final source of truth for completed compaction entries.
- A `compaction_start reason=threshold` event plus a persisted `type = "compaction"` entry is enough to verify that the runtime setting is working.
- Disabling extensions, skills, prompt templates, themes, and context files keeps the test focused on Pi core compaction behavior.

## Artifacts

Repository artifacts:

- `agents/pi-coding-agent/templates/settings.json`
- `internal/profiles/home-manager/core.nix`
- `flake-parts/wrapped-tools.nix`
- `docs/devlog/2026-04-24-pi-aggressive-compaction-defaults.md`
- `docs/devlog/2026-04-28-pi-auto-compaction-verification.md`

Runtime/test artifacts:

- `/tmp/pi-compact-test/run.sh`
- `/tmp/pi-compact-test/run-threshold.sh`
- `/tmp/pi-compact-test/smoke.jsonl`
- `/tmp/pi-compact-test/run-20260428T141422Z`
- `/tmp/pi-compact-test/threshold-20260428T141458Z`
- `/tmp/pi-compact-test/threshold-20260428T141458Z/events.jsonl`
- `/tmp/pi-compact-test/threshold-20260428T141458Z/turn-1.jsonl`
- `/tmp/pi-compact-test/threshold-20260428T141458Z/turn-2.jsonl`
- `/tmp/pi-compact-test/threshold-20260428T141458Z/sessions/2026-04-28T14-14-59-358Z_019dd471-781d-767a-b309-89ce10d284dc.jsonl`

## Verification Status

- [x] Tracked settings contain compaction block.
- [x] Active host settings contain the same compaction block.
- [x] Home Manager path uses tracked template.
- [x] Wrapped Pi path uses tracked template.
- [x] Low-thinking model access works.
- [x] Overflow automatic compaction observed.
- [x] Incremental proactive threshold automatic compaction observed.
- [x] Persisted session `compaction` entry verified.

## Next Steps

- [ ] If the desired policy is truly "50% for every model", replace the fixed `reserveTokens` approach with a model-aware or percentage-aware mechanism if Pi supports one later.
- [ ] Consider adding a short reference note explaining that the current toolnix setting is token-reserve based, not percentage based.
- [ ] Consider turning `/tmp/pi-compact-test/run-threshold.sh` into a tracked smoke-test script only if maintainers want repeatable live-model verification.
