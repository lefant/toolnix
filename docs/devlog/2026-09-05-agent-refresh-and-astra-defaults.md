# Coding-agent refresh and Astra defaults

## Changes

Updated `llm-agents` in both lockfiles from `5dccb49e725e998cd006a13b423b3f58bcc2122e` to `896d09ccef580902e01e716e6f4646421087c252`, the latest upstream revision resolved on 2026-09-05. Its transitive bun2nix, flake-parts, and nixpkgs pins changed too. Unrelated top-level inputs, including skills and Toolnix's primary nixpkgs, stayed unchanged.

Observed package versions:

| Tool | Previous | Updated |
|---|---|---|
| Pi | 0.84.2 | 0.85.0 |
| Codex | 0.147.0 | 0.153.4 |
| OpenCode | 1.18.18 | 1.18.29 |
| Claude Code | 2.1.233 | 2.1.261 |
| Amp | 0.0.1786924891-g5a5391 | 0.0.1788580839-ga71d30 |
| Beads | 1.2.2 | 1.2.2 |
| agent-browser | 0.34.0 | 0.36.0 |

These are the current versions packaged by the shared input, not independently installed npm releases. Beads remains unchanged; the optional browser package updates with the same input.

Updated the three tracked primary defaults:

- Pi: `openai-codex` / `gpt-6-astra` / `high`.
- Codex: `gpt-6-astra` / `high`.
- OpenCode: `openai/gpt-6-astra` / provider `reasoningEffort: high`.

All three already specified high effort. OpenCode's small model remains `openai/gpt-5.6-luna-fast`. Pi compaction, permission policy, and credential ownership remain unchanged. Corrected Codex's obsolete seed-only container comments and the model reference's distinction between managed defaults and local experimental backends.

## Review observations

- OpenCode 1.18.18 did not expose Astra after a model refresh, despite its downloaded catalog containing Astra. Version 1.18.29 lists both Astra and Astra-fast. No custom model workaround was added.
- Home Manager force-manages all three settings files. Devenv does not update them.
- Wrapped Pi preserves existing settings, including valid symlinks to older store paths. A fresh wrapper state uses the new template; existing wrapper users need an explicit model override or a deliberate settings update.
- Pi 0.85.0 supports per-model thinking defaults, which can override the general default. No such override is tracked here.
- Existing permissive OpenCode permissions and the `codex --yolo` shell alias were not changed by this model/version update.
- The manual diff check found no further issues. Independent review was unavailable: all four reviewer dispatches failed before launch because the harness could not discover the temporary reviewer agent.

## Verification

Passed:

- `nix flake check --accept-flake-config`: all seven checks.
- Home Manager activation-package build, with output at `/tmp/toolnix-astra-hm`.
- Wrapped Pi build, with output at `/tmp/toolnix-astra-pi`.
- `devenv shell -- true`.
- Version probes for all seven packages above.
- JSON/TOML assertions for Astra/high and unchanged OpenCode small-model selection.
- Lockfile assertions for matching `llm-agents` revisions/hashes and unchanged unrelated top-level inputs.
- Byte comparisons between the three tracked templates and generated Home Manager files.
- Fresh wrapped Pi state: version 0.85.0, Astra/high settings, and auth readiness.
- Pi Astra catalog and auth checks, plus a tool-free, context-free Astra/high prompt that returned `OK`.
- Updated OpenCode catalog refresh lists Astra.
- `git diff --check`.

No unit tests were added for literal configuration and dependency changes. Parsed configuration assertions, generated-file checks, CLI probes, and existing flake checks provide the verification instead.

## Runtime limitations and rollout

Codex's strict-config smoke run accepted Astra/high, but inference failed because the existing local OAuth refresh token had already been used (`refresh_token_reused`, HTTP 401). OpenCode inference likewise failed with `Token refresh failed: 401`. These failures do not establish an Astra incompatibility; account access and successful high-effort inference remain unverified in those two clients. Credentials were not copied, replaced, or migrated. Reauthenticate each client and repeat its smoke test.

After build verification, the user authorized local activation and a commit/push. Activated `/tmp/toolnix-astra-hm/activate` successfully. The active generation is `/nix/store/bmzfz0jadlhx77s9ywlk204yk0i9ipw7-home-manager-generation`; the previous generation is `/nix/store/0ia700331bdb2a8rkbg2avv5crcpq7g7-home-manager-generation`.

Post-activation checks passed:

- A fresh login zsh resolves all six baseline coding-agent commands to the updated versions above.
- All three persistent settings files byte-match their tracked templates and specify Astra/high.
- `scripts/check-opinionated-zsh.sh` and `scripts/check-opinionated-tmux.sh` pass.

The optional `agent-browser` package was built and version-checked, but is not enabled on this host and is not on its normal PATH. Existing agent processes, resumed sessions, and project overrides can still retain old versions or selections; start a new process/session to use the activated defaults.

Related plan: [agent refresh and Astra defaults](../plans/2026-09-05-agent-refresh-and-astra-defaults.md).
