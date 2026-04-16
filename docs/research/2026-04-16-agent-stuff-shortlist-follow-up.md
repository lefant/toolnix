# 2026-04-16 agent-stuff shortlist follow-up

## Scope

This note continues the earlier `mitsuhiko/agent-stuff` review and focuses on the remaining shortlist items that looked plausibly relevant to `toolnix` and the existing `lefant/agent-skills` bundle.

It covers:

- `tmux`, `github`, and `mermaid` compared against the current `lefant/agent-skills` equivalents
- how `librarian` could fit with current `hackbox-ctrl` / `toolnix` repository-shape guidance
- `pi-share` vs `badlogic/pi-share-hf`
- what `summarize` actually does

## Inputs reviewed

### agent-stuff

- `/tmp/agent-stuff/skills/tmux/SKILL.md`
- `/tmp/agent-stuff/skills/github/SKILL.md`
- `/tmp/agent-stuff/skills/mermaid/SKILL.md`
- `/tmp/agent-stuff/skills/mermaid/tools/validate.sh`
- `/tmp/agent-stuff/skills/librarian/SKILL.md`
- `/tmp/agent-stuff/skills/librarian/checkout.sh`
- `/tmp/agent-stuff/skills/pi-share/SKILL.md`
- `/tmp/agent-stuff/skills/pi-share/fetch-session.mjs`
- `/tmp/agent-stuff/skills/summarize/SKILL.md`
- `/tmp/agent-stuff/skills/summarize/to-markdown.mjs`

### lefant / toolnix / hackbox-ctrl context

- `/home/exedev/git/lefant/agent-skills/lefant/github-access/SKILL.md`
- `/home/exedev/git/lefant/agent-skills/lefant/github-get-pr-comments/SKILL.md`
- `/home/exedev/git/lefant/agent-skills/lefant/mermaid-diagrams/SKILL.md`
- `/home/exedev/git/lefant/agent-skills/vendor/mitsuhiko/tmux/SKILL.md`
- `docs/reference/architecture.md`
- `/tmp/hackbox-ctrl/README.md`
- `/tmp/hackbox-ctrl/docs/specs/hackbox-ctrl-inventory-architecture.md`
- `/tmp/hackbox-ctrl/docs/specs/project-environment-manifest.md`
- `/tmp/hackbox-ctrl/docs/reference/readiness-validation.md`
- `/tmp/hackbox-ctrl/docs/decisions/2026-03-28_adopt-toolnix-as-primary-shared-nix-repo.md`

### pi-share-hf

- `/tmp/pi-share-hf/README.md`
- `/tmp/pi-share-hf/src/index.ts`
- `/tmp/pi-share-hf/src/cli.ts`
- `/tmp/pi-share-hf/src/collect.ts`
- `/tmp/pi-share-hf/src/reject.ts`
- `/tmp/pi-share-hf/src/upload.ts`

## `tmux`, `github`, `mermaid` vs current `lefant/agent-skills`

### `tmux`

#### Result

No net new skill content.

#### Why

The current `lefant/agent-skills` bundle already vendors `mitsuhiko/agent-stuff`'s `tmux` skill directly at:

- `/home/exedev/git/lefant/agent-skills/vendor/mitsuhiko/tmux/`

The reviewed `SKILL.md` content matches the upstream `agent-stuff` version in substance.

#### Practical takeaway

For `tmux`, the answer is effectively:

- already present
- already aligned
- no extra adoption work needed unless the helper scripts or wording should be patched locally

#### Relevance to toolnix

High practical value, but not a new candidate. It is already part of the shared bundle and already fits the current `toolnix` agent baseline well.

## `github`

### Result

`agent-stuff`'s `github` skill is substantially weaker than the existing `lefant` GitHub skills.

### `agent-stuff/github`

Strengths:

- very small
- low-friction
- good as a quick reminder to use `gh pr`, `gh run`, and `gh api`

Limitations:

- assumes `gh` CLI
- no fallback path
- no auth workflow guidance beyond implicit `gh` use
- no structured PR-review workflow
- no local-project-context integration
- no references or troubleshooting material

### `lefant/github-access`

Strengths:

- explicit `GH_TOKEN` preflight
- adapts between `gh` and `curl`
- includes richer operation coverage
- includes reference docs for:
  - `gh`
  - `curl`
  - MCP tools
  - troubleshooting
- better fit for mixed environments and reproducible agent behavior

### `lefant/github-get-pr-comments`

This adds an additional workflow layer that `agent-stuff/github` does not attempt:

- collect PR comments and reviews
- combine them with recent local docs/context
- present an organized response plan

### Practical takeaway

For `toolnix` and the current shared bundle:

- `agent-stuff/github` is not a better replacement
- the existing `lefant` skills already supersede it

If anything is worth borrowing, it is only the lightweight reminder that `gh api` is often the shortest path for awkward GitHub queries. That is a note-level improvement, not a new-skill adoption candidate.

## `mermaid`

### Result

`agent-stuff/mermaid` and `lefant/mermaid-diagrams` are complementary, not competing.

### `agent-stuff/mermaid`

Primary focus:

- executable validation
- parse/render confirmation with Mermaid CLI
- optional ASCII preview

Key value:

- tells the agent to draft standalone `.mmd` first
- validates syntax by rendering, not by eyeballing
- provides a concrete helper script:
  - `tools/validate.sh`

Limitations:

- very little guidance on diagram design quality
- assumes Node/npm runtime tooling
- mostly a "make sure this renders" skill, not a "make this diagram good" skill

### `lefant/mermaid-diagrams`

Primary focus:

- diagram structure
- readability
- hierarchy layout patterns
- color/use/style conventions

Key value:

- better authoring heuristics
- stronger guidance for architectural docs and repo maps
- well aligned with the kind of Mermaid diagrams already used in `toolnix` and `hackbox-ctrl`

Limitations:

- no built-in validation helper
- no render-time proof that the diagram actually parses

### Practical takeaway

Current state:

- `lefant/mermaid-diagrams` is better for authoring quality
- `agent-stuff/mermaid` is better for validation workflow

So the best merged shape would be:

- keep `lefant/mermaid-diagrams` as the main skill
- optionally add a small validation helper inspired by `agent-stuff/mermaid/tools/validate.sh`

This is the strongest concrete follow-up from this comparison.

### Adoption value

Moderate.

Not a reason to add another separate Mermaid skill, but a good reason to consider extending the existing one with optional validation tooling.

## How `librarian` could fit with current `hackbox-ctrl` / `toolnix` guidance

## First finding: current durable docs do not appear to standardize `~/git/external`

In the currently checked-out `toolnix` docs and the current public `hackbox-ctrl` repo docs reviewed here, I did **not** find a durable documented convention that explicitly standardizes reference clones under `~/git/external`.

The explicit durable checkout guidance I did find was:

- normal editable repo checkouts use `~/git/lefant/...`
- project-target bootstrap should not require target-side shared repo clones
- inventory manifests should reference repos externally rather than embedding copies
- new consumer guidance should avoid requiring sibling checkouts or vendored shared repos

So the current published direction is mostly:

- avoid unnecessary durable shared clones
- prefer remote flake consumption for shared infra
- keep editable, owned repos in normal named checkouts

That does not conflict with `~/git/external`, but it does mean `~/git/external` looks more like an operator habit or private convention than a strong current public rule in the reviewed docs.

## What `librarian` does well

`librarian` solves a real agent problem:

- user or docs reference a remote repository
- agent wants local grep/read/search speed
- agent should not reclone it every time
- agent should avoid turning every reference repo into a human-managed durable checkout

Its design choices fit that use case well:

- stable path
- partial clone
- throttled refresh
- fast-forward only when safe
- advice not to edit directly in the shared cache

Cache location:

- `~/.cache/checkouts/<host>/<org>/<repo>`

That is a strong fit for read-only reference research.

## Where `librarian` fits cleanly

It fits best as:

- an **agent-side ephemeral/reference checkout cache**
- mainly for research, comparison, or code-reading tasks
- primarily on operator/control-host machines, not as a target bootstrap dependency

That aligns with current `toolnix` / `hackbox-ctrl` direction because:

- target bootstrap paths are explicitly moving away from requiring shared repo clones
- reference repos are supposed to stay external rather than copied into inventory
- thin project integration is preferred over sibling-checkout assumptions

So `librarian` is compatible **if it is treated as optional research infrastructure**, not as a required workspace layout.

## Where `librarian` conflicts with a hypothetical `~/git/external` convention

If the intended human-facing convention is:

- keep durable reference checkouts under `~/git/external/...`

then raw `librarian` does not match that directly because it stores repos under:

- `~/.cache/checkouts/...`

That mismatch matters because cache semantics and human-worktree semantics are different.

`librarian`'s own guidance already implies this split:

- use the cache for reuse
- do not edit in place
- create a separate worktree/copy when edits are needed

## Best-fit model for lefant workflows

The cleanest fit would be a two-tier model:

1. **Default**: use `librarian` cache for transient read-only reference repos
   - path under `~/.cache/checkouts/...`
   - agent-owned
   - safe to refresh
2. **Promotion path**: if a reference repo becomes an actual working checkout, promote it into a human-facing durable location
   - for example `~/git/external/...`
   - or another explicitly chosen worktree path

That preserves the current architectural direction:

- no mandatory extra durable clones
- no target-side bootstrap dependency on shared repo checkouts
- no confusion between cache and editable worktree

## If adopted in toolnix

The best version would likely be an adapted skill or helper with one of these shapes:

### Option A: keep upstream semantics

- leave cache root at `~/.cache/checkouts`
- document it as a reference-repo cache only
- add a small note describing when to promote to a real checkout

### Option B: lefant-flavored wrapper

Wrap `checkout.sh` with a tiny policy layer such as:

- cache remains under `~/.cache/checkouts`
- optional `--promote ~/git/external/...`
- or optional `--worktree-root ~/git/external`

That would fit the likely desired operator UX better than replacing the cache root entirely.

### Option C: replace with a durable-clone policy

This is the weakest fit.

If `librarian` were changed to clone directly into `~/git/external`, it would lose a lot of its value as a disposable agent cache and would blur the line between:

- agent temporary references
- human-maintained worktrees

## Conclusion on `librarian`

`librarian` is still one of the most interesting remaining shortlist items.

But its best fit is **not** "new default checkout convention".
Its best fit is:

- read-only reference-repo cache
- optional operator helper
- explicit separation from normal editable repo layout

If the `~/git/external` convention matters, `librarian` should be wrapped or documented as a lower-level cache behind that convention, not treated as a direct replacement for it.

## `pi-share` vs `badlogic/pi-share-hf`

### Short version

They are related, but they solve very different problems.

- `agent-stuff/pi-share` is a **session loader / inspector** for already-shared exported sessions
- `pi-share-hf` is a **publishing pipeline** for collecting local sessions, redacting them, reviewing them, and uploading them to a Hugging Face dataset

So `pi-share-hf` is not a better version of `pi-share`.
It is a different layer.

## `agent-stuff/pi-share`

Purpose:

- fetch a single shared session export from gist-backed pi-share URLs
- decode embedded session data from `session.html`
- expose the session as JSON, JSONL entries, system prompt, tools, or a human summary

Key properties:

- works on publicly shared sessions
- gist-centric
- read-only
- good for ad hoc inspection and analysis
- includes a human-summary mode using Pi itself

Best use cases:

- inspect a session somebody shared by URL
- analyze one exported session quickly
- count tool calls or extract user turns
- understand prompting behavior in a public/shared trace

## `pi-share-hf`

Purpose:

- collect local Pi session files for one OSS project
- redact known secrets
- reject denied topics/patterns
- run TruffleHog
- run LLM review for publishability
- upload passing sessions to a Hugging Face dataset

Key properties:

- local workspace pipeline
- project-scoped
- incremental stateful processing
- publication-oriented
- safety/review heavy
- designed for repeated dataset maintenance, not one-off inspection

Best use cases:

- build a public dataset of project sessions over time
- curate a shareable corpus
- track what is uploadable and what was blocked
- manage repeated publication safely

## Relationship

The two tools are complementary by layer:

- `pi-share` = inspect an exported session
- `pi-share-hf` = create and maintain a reviewed corpus of publishable sessions

A reasonable future stack could use both:

1. publish redacted sessions through `pi-share-hf`
2. inspect individual resulting sessions with a `pi-share`-style loader or related analysis tooling

## Relevance to toolnix

For present `toolnix` needs, `pi-share` is the more immediately relevant idea because it helps with:

- shared-session introspection
- debugging and analysis of a session someone already exported
- Pi-native workflow inspection

`pi-share-hf` is more specialized. It matters if the goal becomes:

- public trace publication
- research corpus creation
- repeatable redaction/review/upload of local Pi sessions

That is a meaningful adjacent space, but not the same adoption question.

## What `summarize` does

### Core function

`summarize` is a small document-ingestion wrapper around:

- `uvx markitdown`
- optional `pi` summarization via `claude-haiku-4-5`

It converts:

- URLs
- PDFs
- DOCX/PPTX-like files
- local text or HTML-like documents

into Markdown, then optionally asks Pi to summarize the converted Markdown.

### Practical workflow

The helper script `to-markdown.mjs` does this:

1. accept a URL or local file path
2. run `uvx --from 'markitdown[pdf]' markitdown <input>`
3. optionally write the produced Markdown to a temp file or specified path
4. if `--summary` is used, call `pi --provider anthropic --model claude-haiku-4-5 --no-tools --no-session`
5. print:
   - an executive summary
   - key bullets
   - open questions / missing info
6. always tell you where the full converted Markdown was written when summarizing

### Why it is useful

It turns awkward documents into something agents can inspect like ordinary text.

That makes it useful for:

- reading specs in PDF/DOCX form
- converting web pages into Markdown before analysis
- getting a quick focused summary before deeper reading

### Important nuance

The quality of the summary depends heavily on the extra prompt/context.

The skill itself explicitly recommends prompts like:

- what to focus on
- what audience the summary is for
- what facts or constraints to extract

So it is best thought of as:

- Markdown conversion first
- targeted summarization second

not as a generic magical summarizer.

### Overlap with current lefant bundle

This overlaps with the existing `markdown-converter` skill already present in the current lefant bundle.

Difference in emphasis:

- `markdown-converter`
  - stronger pure conversion reference
  - broader format/options cheat sheet
- `summarize`
  - adds a convenience wrapper for temp-file output plus immediate Pi summarization

So the most interesting part of `summarize` is not the conversion itself. It is the lightweight:

- convert to Markdown
- save full output
- summarize with a focused prompt

workflow wrapper.

## Overall takeaways from this pass

### Strongest remaining practical idea

- `librarian`
  - as a read-only reference-repo cache, not as a new default durable checkout rule

### Best small concrete improvement to existing bundle

- add `agent-stuff/mermaid`-style validation helpers to the existing `mermaid-diagrams` skill

### Lowest-value adoption candidates from this pass

- `github`
  - existing `lefant` skills already exceed it
- `tmux`
  - already present as vendored upstream content

### Adjacent but different space

- `pi-share-hf`
  - interesting for public session dataset publishing
  - not a direct replacement for `pi-share`
