---
date: 2026-04-15T00:00:00Z
researcher: pi
git_commit: 60836161b1ada3e51525fb7f2bb0c4f79e6562f0
branch: main
repository: toolnix
topic: "Notes on reusable Pi patterns from mitsuhiko/agent-stuff"
tags: [research, pi, extensions, skills, mitsuhiko, agent-stuff]
status: complete
last_updated: 2026-04-15
last_updated_by: pi
last_updated_note: "Initial research note covering answer.ts, loop.ts, selected skills, and answer.ts vs Pi qna.ts comparison"
---

# Research: reusable Pi patterns from `mitsuhiko/agent-stuff`

## Research question

Which patterns in `mitsuhiko/agent-stuff` look worth tracking for future `toolnix` / shared-agent adoption, with emphasis on the `/answer` and `/loop` extensions plus a small set of notable skills?

## Summary

Yes: the `/answer` extension is present in `mitsuhiko/agent-stuff` as `extensions/answer.ts`.

That makes the earlier suspicion correct at least at the repository level: there is a real `/answer` extension in Mitsuhiko's public repo, and it is more advanced than Pi's shipped `examples/extensions/qna.ts` example.

The two strongest extension ideas in this pass are:

- `extensions/answer.ts` — a structured question-extraction + interactive answer-entry TUI
- `extensions/loop.ts` — a durable self-follow-up loop with explicit breakout signaling, UI status, and compaction awareness

Among the reviewed skills, the strongest reusable patterns are:

- `skills/librarian` — stable cached remote-repo checkout flow under `~/.cache/checkouts/...`
- `skills/pi-share` — loader for Pi session-share URLs and gist-backed session transcripts
- `skills/summarize` — practical file/URL → Markdown → optional Haiku summary wrapper around `markitdown`
- `skills/tmux` — disciplined private-socket tmux workflow with helper scripts and user-visible monitoring commands
- `skills/mermaid` — simple validate-before-embed workflow using Mermaid CLI

`skills/github` is useful, but comparatively lightweight: it is mostly a concise operational reminder to prefer `gh` with `--repo`, `--json`, and `gh api` for advanced queries.

## Repo context

At the time of review, the inspected upstream state was:

- repo: `https://github.com/mitsuhiko/agent-stuff`
- inspected commit: `2b70e8d53647c1e0277bd54dbbb2519cb5bea92b`

The repo README describes it as Mitsuhiko's shared Pi skills/extensions repo and notes that it is published on npm as `mitsupi` for Pi package loading.

## Findings

### 1. `extensions/answer.ts` is the public `/answer` extension

Location:

- `extensions/answer.ts`

What it does:

1. finds the last completed assistant message on the current branch
2. runs a question-extraction prompt that asks for structured JSON
3. prefers a cheap extraction model when available:
   - `openai-codex/gpt-5.1-codex-mini`
   - otherwise `anthropic/claude-haiku-4-5`
   - otherwise current model
4. parses extracted questions into:
   - `question`
   - optional `context`
5. opens a custom interactive TUI for answering questions one by one
6. submits the compiled answers back into the session as a follow-up message

Why it matters:

- This is not just the shipped `qna.ts` example renamed.
- It upgrades the pattern from “dump prompt into editor” to a proper multi-question answer workflow.
- It demonstrates a good Pi extension pattern: use a cheap structured-output model for extraction, then hand off to a purpose-built TUI for user interaction.

Notable implementation details:

- registers both:
  - `/answer`
  - `ctrl+.` shortcut
- uses JSON extraction instead of line-based text formatting
- uses a custom `QnAComponent` built on `@mariozechner/pi-tui`
- preserves answers across question navigation
- supports question context display
- sends answers back via `pi.sendMessage(..., { triggerTurn: true })`

Practical value for `toolnix` / shared skills:

- strong candidate if a future shared extension layer is desired
- especially useful for review, clarification, or agent-to-user handoff workflows
- cleaner UX than the stock `qna.ts` example

### 1b. `answer.ts` vs Pi's shipped `examples/extensions/qna.ts`

Pi already ships a smaller related example at:

- `examples/extensions/qna.ts`

That example:

- registers `/qna`
- finds the last assistant message
- runs a question-extraction prompt against the current model
- writes a plain text Q/A template into the editor via `ctx.ui.setEditorText()`
- leaves final editing and submission to the user in the normal editor

By contrast, `agent-stuff/extensions/answer.ts`:

- registers `/answer` and `ctrl+.`
- prefers a cheaper extraction model instead of always using the current model
- asks for structured JSON output instead of line-based text output
- opens a purpose-built multi-question TUI instead of dumping text into the normal editor
- supports question-local context display
- preserves answers while navigating between questions
- sends the compiled answers back into the session automatically

Net comparison:

- `qna.ts` is a minimal example / proof of pattern
- `answer.ts` is the production-grade version of that idea

Tradeoff summary:

- `qna.ts`
  - simpler
  - easier to study and adapt
  - lower implementation complexity
  - weaker UX for multi-question flows
- `answer.ts`
  - stronger interactive UX
  - better structure and navigation
  - more reusable for real workflows
  - more code, more custom TUI surface, more moving parts

Recommendation:

- if the goal is to understand how to enable a basic question-extraction workflow in Pi, start with `qna.ts`
- if the goal is to adopt a serious interactive answer workflow, `answer.ts` is the more interesting upstream reference

### 2. `extensions/loop.ts` is a serious loop-control pattern, not a toy auto-continue

Location:

- `extensions/loop.ts`

What it does:

- adds `/loop`
- adds a tool `signal_loop_success`
- keeps sending a follow-up prompt after each `agent_end` until the model explicitly calls the breakout tool

Loop modes:

- `tests` — loop until tests pass
- `custom` — loop until a user-specified condition is satisfied
- `self` — loop until the agent decides it is done

Why it stands out:

This is a fairly complete control-loop design, not just “auto continue forever.”

Important behaviors:

- loop state persists in session entries via a custom entry type (`loop-state`)
- active loop status is shown as a widget in the UI
- the loop keeps a turn count
- it summarizes the breakout condition for compact status text
- it is compaction-aware and injects instructions so the breakout condition survives compaction
- it prompts the user whether to break the loop if the last assistant message was aborted

Notable implementation details:

- `pi.appendEntry()` used for durable state
- `agent_end` hook used to trigger the next follow-up turn
- `session_before_compact` customizes compaction instructions so loop intent is preserved
- lightweight model call used to create a short loop-status summary
- supports both CLI args and interactive preset selection UI

Why it matters:

- this is a reusable pattern for bounded iterative coding loops
- it shows how to make loop behavior survivable across session changes and compaction
- it could inform any future “run until green” or “agent autopilot with explicit stop condition” feature set

Practical value for `toolnix` / shared skills:

- strong research candidate
- probably extension-only, not skill-only
- useful if future tracked Pi setup wants a controlled iterative workflow for tests, fixes, or review loops

### 3. `skills/summarize` is a pragmatic document-ingest pipeline

Locations:

- `skills/summarize/SKILL.md`
- `skills/summarize/to-markdown.mjs`

Pattern:

- use `uvx --from 'markitdown[pdf]' markitdown` to convert URLs or local files into Markdown
- optionally summarize the Markdown with `pi --provider anthropic --model claude-haiku-4-5 --no-tools --no-session -p ...`
- always write a temp `.md` file when summarizing so the full converted document remains inspectable

Why it is useful:

- combines conversion + summarization in one repeatable wrapper
- encourages passing explicit summary intent instead of producing low-value generic summaries
- keeps original converted Markdown accessible for follow-up analysis

Implementation details worth noting:

- supports URL or local path input
- auto-enables PDF extra for markitdown
- truncates very large documents before summarization, preserving head and tail
- summary prompt asks for:
  - executive summary
  - key facts / decisions / requirements
  - open questions / missing info

Practical value:

- good skill pattern for agent environments where users hand agents arbitrary documents
- likely portable with minimal changes if `uvx`, `markitdown`, and `pi` are available

### 4. `skills/tmux` is a disciplined private-socket tmux operating model

Locations:

- `skills/tmux/SKILL.md`
- `skills/tmux/scripts/find-sessions.sh`
- `skills/tmux/scripts/wait-for-text.sh`

Core idea:

- treat tmux as a programmable terminal backend for interactive CLIs
- isolate agent sessions on a private socket path
- always tell the user how to observe the live tmux session themselves

Notable rules:

- use a dedicated socket under `${TMPDIR:-/tmp}/claude-tmux-sockets`
- always print monitor commands immediately after session start
- prefer literal `send-keys` usage
- poll pane output with helper scripts rather than relying on weaker synchronization shortcuts
- explicitly special-case interactive Python and debugger workflows

Helper scripts:

- `find-sessions.sh` lists sessions on a socket or scans all sockets in the shared socket dir
- `wait-for-text.sh` polls pane output for a regex/fixed string with timeout and prints recent pane history on failure

Why it matters:

- the skill is not just command snippets; it encodes operator discipline
- the requirement to always print user monitor commands is especially good human-factors guidance
- the helper scripts make the workflow more deterministic

Practical value:

- useful reference if `toolnix` ever wants a tracked tmux-control skill beyond the existing tmux skill bundle
- strong example of pairing markdown instructions with small helper scripts

### 5. `skills/github` is a compact operational gh guide

Location:

- `skills/github/SKILL.md`

What it covers:

- use `gh` for PRs, CI runs, and API access
- prefer explicit `--repo owner/repo` when outside a git repo
- use `gh run`, `gh pr checks`, `gh run view --log-failed`
- use `gh api` and `--json` / `--jq` for structured output

Assessment:

- useful as a minimal baseline skill
- not deeply novel, but clean and portable
- best viewed as a thin convenience skill rather than a major workflow invention

### 6. `skills/librarian` is one of the strongest reusable skill ideas in the repo

Locations:

- `skills/librarian/SKILL.md`
- `skills/librarian/checkout.sh`

Core idea:

- normalize remote repo references into stable cached checkouts under:
  - `~/.cache/checkouts/<host>/<org>/<repo>`
- reuse those checkouts for later research instead of repeatedly recloning repos

What `checkout.sh` does:

- accepts many repo forms:
  - `owner/repo`
  - `github.com/owner/repo`
  - `https://...`
  - `git@...`
  - GitHub deep links
- clones with `--filter=blob:none`
- throttles refresh via a timestamp file (default 300s)
- fetches and fast-forwards when safe
- can print only the resolved path via `--path-only`

Why it matters:

- this directly improves research/review workflows around remote repos
- it encodes a good local-cache convention instead of leaving every session to improvise
- it keeps analysis paths stable and predictable

Practical value:

- very strong candidate for future shared-agent workflows
- especially relevant when users often hand the agent GitHub URLs for reference work
- likely useful even outside Pi-specific contexts

### 7. `skills/mermaid` is simple but operationally sound

Locations:

- `skills/mermaid/SKILL.md`
- `skills/mermaid/tools/validate.sh`

Pattern:

- draft Mermaid in a standalone `.mmd` file first
- validate by parsing + rendering with Mermaid CLI
- optionally print an ASCII preview via `beautiful-mermaid`
- only embed into Markdown after validation succeeds

Why it is useful:

- pushes diagram validation earlier
- keeps validation concrete and shell-driven
- the helper script makes Mermaid syntax errors fail fast

Assessment:

- not a large architectural pattern, but a good “tool-wrapped discipline” example
- portable wherever Node + `npx` are acceptable

### 8. `skills/pi-share` is a notable Pi-specific inspection skill

Locations:

- `skills/pi-share/SKILL.md`
- `skills/pi-share/fetch-session.mjs`

What it does:

- loads Pi shared-session URLs or gist IDs
- fetches the backing GitHub Gist
- extracts base64 session data embedded in `session.html`
- exposes sub-views:
  - `--header`
  - `--entries`
  - `--system`
  - `--tools`
  - `--human-summary`

Interesting details:

- supports multiple share-host aliases (`shittycodingagent.ai`, `buildwithpi.ai`, `buildwithpi.com`, `pi.dev`)
- caches fetched decoded sessions under temp storage
- `--human-summary` condenses the session and asks Haiku to summarize what the human did, not what the agent did

Why it matters:

- this is a strong Pi-native observability / analysis utility
- especially useful for studying prompting style, intervention patterns, and session behavior
- the “human summary” mode is a distinctive analysis layer, not just a raw fetcher

Practical value:

- strong Pi ecosystem utility
- worth tracking if `toolnix` ever wants better shared-session analysis or debugging aids

## Comparative takeaways

### Highest-value extension patterns

1. `answer.ts`
   - strongest immediate UX pattern
   - concrete upgrade over Pi's simple `qna.ts` example
2. `loop.ts`
   - strongest control-flow pattern
   - especially interesting for persistent bounded automation

### Highest-value skill patterns

1. `librarian`
   - most broadly reusable repo-research utility
2. `pi-share`
   - most interesting Pi-specific introspection utility
3. `summarize`
   - strongest document ingestion pattern
4. `tmux`
   - strongest interactive-terminal operations pattern

### Lower-complexity but still useful

- `github`
- `mermaid`

## Adoption notes for `toolnix`

These notes are research only, not an implementation recommendation yet.

Most plausible future candidates to port or adapt:

- `/answer`
  - if `toolnix` grows a tracked Pi extension set
- `librarian`
  - if remote-repo reference work becomes a common supported workflow
- `pi-share`
  - if session-share inspection becomes part of tracked Pi operations
- `summarize`
  - if a general document-ingest workflow is wanted in the shared skills tree

More specialized / cautionary candidates:

- `/loop`
  - powerful, but changes agent control flow and should be adopted deliberately
- `tmux`
  - useful, but helper scripts and operator expectations need to align with existing toolnix tmux conventions
- `mermaid`
  - low risk, but depends on Node tooling at runtime

## Conclusion

The user's pointer was correct: `mitsuhiko/agent-stuff` does contain a real `extensions/answer.ts`.

The two most interesting extension patterns in this pass are:

- `answer.ts` for structured interactive response collection
- `loop.ts` for persistent bounded auto-follow-up control

The most reusable skill patterns are:

- `librarian`
- `pi-share`
- `summarize`
- `tmux`

If a later `toolnix` or shared-skills pass wants outside inspiration for Pi-native workflows, this repo is a credible source of practical patterns rather than just toy examples.

## References

### Upstream repo

- `https://github.com/mitsuhiko/agent-stuff`
- `https://github.com/mitsuhiko/agent-stuff/blob/main/extensions/answer.ts`
- `https://github.com/mitsuhiko/agent-stuff/blob/main/extensions/loop.ts`
- `https://github.com/mitsuhiko/agent-stuff/tree/main/skills/summarize`
- `https://github.com/mitsuhiko/agent-stuff/tree/main/skills/tmux`
- `https://github.com/mitsuhiko/agent-stuff/tree/main/skills/github`
- `https://github.com/mitsuhiko/agent-stuff/tree/main/skills/librarian`
- `https://github.com/mitsuhiko/agent-stuff/tree/main/skills/mermaid`
- `https://github.com/mitsuhiko/agent-stuff/tree/main/skills/pi-share`

### Local inspected files

- `/tmp/agent-stuff/README.md`
- `/tmp/agent-stuff/extensions/answer.ts`
- `/tmp/agent-stuff/extensions/loop.ts`
- `/nix/store/pla9k91nw539sg214hwl6aky90zlgfhy-pi-0.67.2/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/qna.ts`
- `/tmp/agent-stuff/skills/summarize/SKILL.md`
- `/tmp/agent-stuff/skills/summarize/to-markdown.mjs`
- `/tmp/agent-stuff/skills/tmux/SKILL.md`
- `/tmp/agent-stuff/skills/tmux/scripts/find-sessions.sh`
- `/tmp/agent-stuff/skills/tmux/scripts/wait-for-text.sh`
- `/tmp/agent-stuff/skills/github/SKILL.md`
- `/tmp/agent-stuff/skills/librarian/SKILL.md`
- `/tmp/agent-stuff/skills/librarian/checkout.sh`
- `/tmp/agent-stuff/skills/mermaid/SKILL.md`
- `/tmp/agent-stuff/skills/mermaid/tools/validate.sh`
- `/tmp/agent-stuff/skills/pi-share/SKILL.md`
- `/tmp/agent-stuff/skills/pi-share/fetch-session.mjs`
