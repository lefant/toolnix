---
title: Pi ask_user Tool Required for Compound Workflows
date: 2026-04-29
category: integration-issues
module: Pi Compound Engineering integration
problem_type: integration_issue
component: assistant
symptoms:
  - "Compound Engineering skills referenced Pi's `ask_user` blocking question tool, but Toolnix-managed Pi did not register it"
  - "Tool inspection showed only built-in file/shell tools and `subagent`; `ask_user` was absent"
  - "Interactive Compound workflows could fall back to chat prompts or risk skipping required user choices"
root_cause: missing_tooling
resolution_type: tooling_addition
severity: medium
related_components:
  - Pi extension runtime
  - Home Manager profile
  - wrapped toolnix-pi
  - Compound Engineering skills
tags:
  - pi
  - ask-user
  - compound-engineering
  - extensions
  - home-manager
  - toolnix-pi
---

# Pi ask_user Tool Required for Compound Workflows

## Problem

Compound Engineering skills expect each host agent to provide a blocking question tool before making user-dependent workflow decisions. Pi-specific instructions name the tool as `ask_user`, but Toolnix only installed the `qna`, `loop`, and Compound `subagent` extensions, so default Toolnix-managed Pi sessions had no LLM-callable `ask_user` tool.

## Symptoms

- Compound skills such as `/ce-compound` and related workflows referenced `ask_user` in Pi and required the agent not to silently skip user questions.
- `~/.pi/agent/extensions/answer.ts` and `agents/pi-coding-agent/extensions/qna.ts` were command-style helpers, not LLM-callable tools.
- A tmux reproduction using a temporary tool-listing extension showed `ask_user` missing before the fix:

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

## What Didn't Work

- Relying on `/qna` did not solve the problem. It extracts questions from an assistant response into the editor, but it does not register a callable tool that the model can invoke during a workflow.
- Relying on `answer.ts` did not solve the problem. It is a local command helper and not part of the Toolnix-managed Home Manager or wrapped `toolnix-pi` extension set.
- Running `PI_OFFLINE=1 pi --tools ask_user --no-session -p 'Say ok'` was inconclusive because the prompt did not force a tool call; Pi could answer without proving the tool existed.
- Session history search found no relevant prior sessions within the requested 7-day window.

## Solution

Add a managed Pi extension that registers `ask_user` with `pi.registerTool`, then wire it into both Toolnix Pi consumption paths.

The extension lives at `agents/pi-coding-agent/extensions/ask-user.ts` and registers the expected tool name:

```ts
export default function askUserExtension(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "ask_user",
		label: "Ask User",
		description: "Ask the user a blocking question and return their answer. Use when Compound Engineering skills require explicit user input before proceeding.",
		promptSnippet: "Ask the user a blocking question with optional choices and free-text fallback.",
		promptGuidelines: [
			"Use ask_user when a skill says to use Pi's platform blocking question tool.",
			"Use ask_user before making workflow decisions that require explicit user choice; do not silently choose for the user.",
		],
		parameters: AskUserParamsSchema,
		prepareArguments: normalizeArgs,
		// ...
	});
}
```

The implementation supports the argument shapes likely to come from converted or cross-agent skill instructions:

- `question` plus fallback aliases such as `prompt`, `message`, `title`, or `text`
- string or object options, normalized via `label`, `text`, `title`, or `value`
- `allow_free_text` / `allowFreeText`
- `multi_select` / `multiSelect`
- a non-UI fallback that tells the model to present the question in chat rather than pretending the question was answered

A post-documentation review also hardened the extension against option values that are not strings and made `multi_select` respect `allow_free_text: false` instead of accepting arbitrary editor text in bounded-choice workflows.

Home Manager now installs it next to the other managed Pi extensions in `internal/profiles/home-manager/core.nix`:

```nix
home.file.".pi/agent/extensions/ask-user.ts" = {
  source = ../../../agents/pi-coding-agent/extensions/ask-user.ts;
  force = true;
};
```

The wrapped Pi proof path also seeds it in `flake-parts/wrapped-tools.nix`:

```nix
piAskUserExtension = ../agents/pi-coding-agent/extensions/ask-user.ts;
```

```bash
if [ ! -e "$agent_dir/extensions/ask-user.ts" ]; then
  ln -s "${piAskUserExtension}" "$agent_dir/extensions/ask-user.ts"
fi
```

Validation built and activated the Home Manager profile, confirmed the managed link, and restarted Pi in tmux. After the fix, the registered tools included `ask_user`:

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

A model-backed Pi prompt then forced a real tool call:

```text
Use the ask_user tool to ask exactly: "Pick one" with options "Alpha" and "Beta". After the user answers, echo the selected answer and stop.
```

Pi rendered the blocking selector, selecting `Alpha` returned `User selected: Alpha`, and the assistant echoed `Alpha`.

Final verification commands passed:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
./result/activate
nix flake check --no-build
nix build .#toolnix-pi
```

## Why This Works

Pi extensions can register LLM-callable tools with `pi.registerTool`. Compound Engineering's Pi instructions are written against that mechanism, not against slash commands. Installing `ask-user.ts` into the managed extension directory makes Pi load the tool at startup, so skills that require an explicit user decision can call the same tool name they document.

Wiring the same extension into Home Manager and wrapped `toolnix-pi` keeps the two supported Toolnix Pi entry points aligned. A fix only in `~/.pi/agent/extensions` would leave `nix run .#toolnix-pi` broken; a fix only in the wrapper would leave ordinary Home Manager-managed Pi broken.

## Prevention

- When adding a skill bundle that names platform-specific tools, validate the registered tool list in the target agent, not just startup output or skill discovery.
- Force at least one model-backed tool call during validation when the issue is tool availability; prompts that can be answered without a tool do not prove registration.
- Keep command-style Pi helpers and LLM-callable Pi tools separate in design reviews. Slash commands such as `/qna` do not satisfy workflow requirements that say the model must call a blocking question tool.
- Wire tracked Pi extensions into both default paths: Home Manager-managed `~/.pi/agent` and wrapped `toolnix-pi` state.

## Related Issues

- `docs/devlog/2026-04-29-pi-ask-user-extension.md` records the implementation and tmux validation transcript.
- `docs/devlog/2026-04-16-pi-qna-default-extension.md` is related background for the earlier `/qna` command extension, but it solves a different command-helper problem.
- `docs/specs/compound-engineering-toolnix-integration.md` still has an open question about normalizing Claude-style tool names for Pi; this fix is concrete evidence that tool-name compatibility needs explicit validation.
