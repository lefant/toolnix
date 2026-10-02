# Maintaining Toolnix

This document covers the practical maintainer workflow for the self-hosted `toolnix` repo.

See also:

- [`architecture.md`](architecture.md)
- [`../specs/toolnix-agent-readiness.md`](../specs/toolnix-agent-readiness.md)
- [`credentials.md`](credentials.md)
- [`pi-model-backends.md`](pi-model-backends.md)
- [`../specs/fresh-environment-bootstrap.md`](../specs/fresh-environment-bootstrap.md)
- [`../specs/llm-agents-cache-bootstrap.md`](../specs/llm-agents-cache-bootstrap.md)
- [`../plans/2026-04-05-bootstrap-paths-and-credentials.md`](../plans/2026-04-05-bootstrap-paths-and-credentials.md)
- [`../plans/2026-04-05-exe-vm-bootstrap-proof.md`](../plans/2026-04-05-exe-vm-bootstrap-proof.md)
- [`../plans/2026-03-28-remove-imperative-setup-hook.md`](../plans/2026-03-28-remove-imperative-setup-hook.md)

## What owns what

### Home Manager owns persistent host state

Persistent self-hosted runtime state under `$HOME` is managed by `modules/home-manager/toolnix-host.nix`, including:

- shell and tmux config
- git and SSH config
- persistent agent config files
- shared skills wiring
- session variables
- `.claude.json` activation-time merge behavior

Important boundary:

- `~/.openclaw/openclaw.json` is intentionally **not** Home Manager-managed
- OpenClaw owns that live runtime config on each host
- toolnix rollouts must not replace a valid OpenClaw config with a repo-tracked store symlink

### Devenv owns shell-local behavior

`modules/devenv/default.nix` shapes the active shell only:

- packages
- shell-local environment
- aliases and helper functions
- optional shell features such as `agent-browser`

`devenv` should not be used to provision persistent host runtime state.

### Local secret state stays outside the repo

Local runtime secrets and credentials are still loaded from:

- `~/.env.toolnix`
- legacy fallback: `~/.env.toolbox`

These files are local-only and not repo-managed.

## Common maintainer commands

### Bootstrap a fresh host without a target-side toolnix clone

```bash
scripts/bootstrap-home-manager-host.sh
```

Optional host-label override:

```bash
scripts/bootstrap-home-manager-host.sh --host-name <host-name>
```

This is the tracked public bootstrap artifact for fresh-machine host setup. `--host-name` is optional and otherwise defaults to `hostname -s`.

### Enter the self-hosted project shell

```bash
devenv shell
```

### Non-interactive shell smoke test

```bash
devenv shell -- true
```

### Develop Toolnix and agent-skills together in Amp

Add `github:lefant/agent-skills` as an additional repository in the `lefant/toolnix` Amp project settings. Amp checks additional repositories out next to the primary repository and includes changes from both repositories in the thread's Changes view. Only this primary repository's `.agents/setup` runs automatically; `agent-skills` does not need a separate setup step because Toolnix consumes its files directly.

Normal builds continue to use the `agent-skills` revision pinned in `flake.lock` and `devenv.lock`. An adjacent checkout does not silently change reproducible builds.

For integration work that must test uncommitted `agent-skills` changes, explicitly override the input. These examples assume Amp checked out the additional repository at `../agent-skills`:

```bash
nix --accept-flake-config build \
  .#homeConfigurations.lefant-toolnix.activationPackage \
  --override-input agent-skills path:../agent-skills \
  --no-link
```

After the `agent-skills` change is committed and published, update both Toolnix lockfiles and run the normal checks:

```bash
nix flake update agent-skills
devenv update agent-skills
nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage --no-link
devenv shell -- true
```

### Publish Compound Engineering skills globally in Amp

Toolnix renders the pinned Compound Engineering input as the `compound-engineering-amp-skills` flake package. The repository exporter copies that package into an existing Amp Global User or Workspace Skills repository checkout:

```bash
scripts/export-compound-engineering-amp-skills.sh <global-skills-checkout>
```

The exporter is intentionally local-only. It does not clone the destination, run Git commands, commit, or push. It updates only skill names recorded in `compound-engineering.lock.json`, rejects unmanaged name collisions, preserves unrelated skills, and puts the upstream MIT license in every exported package.

To publish for one user across all Amp projects and threads:

```bash
amp skill repositories
amp clone user-skills <global-skills-checkout>
scripts/export-compound-engineering-amp-skills.sh <global-skills-checkout>
git -C <global-skills-checkout> status --short
git -C <global-skills-checkout> diff --stat
```

Use `amp clone workspace-skills <global-skills-checkout>` instead when a workspace administrator is preparing the shared Workspace Skills repository. Reuse an existing checkout rather than cloning over it.

Review and commit the generated changes in the Global Skills checkout. Pushing that repository publishes the update: new Amp threads load it automatically, while an existing thread needs the `reload_skills` tool.

An Amp maintainer can be asked to carry out the reviewable workflow from this repository with:

> Refresh the Compound Engineering skills in the user's Global Skills repository from Toolnix's pinned input. Reuse or clone the requested Global Skills checkout, run `scripts/export-compound-engineering-amp-skills.sh`, review and validate its diff, commit in that checkout, and ask before pushing it. After an approved push, reload skills in the current thread.

The source and destination responsibilities stay separate:

- Toolnix owns the upstream pin, rendering, validation, and export command.
- The Global Skills repository owns the published snapshot and its Git history.
- Amp or the user owns the explicit commit and push decision.

#### Publish Compound Engineering as one global Amp plugin

When the hosted Skills profile cannot accommodate every Compound package, Toolnix can instead render one Amp directory plugin named `ce`:

```bash
nix --accept-flake-config build .#compound-engineering-amp-plugin --no-link
scripts/export-compound-engineering-amp-plugin.sh <global-plugins-checkout>
```

The plugin registers all 33 packages under concise qualified names. For example, upstream `ce-plan`, `ce-work`, and `lfg` become `ce:plan`, `ce:work`, and `ce:lfg`. Every rendered `SKILL.md` carries the namespace rule needed to resolve cross-skill handoffs while preserving upstream artifact metadata, configuration values, paths, and internal identifiers.

Amp limits an imported plugin item to 200 files. The renderer keeps this collection below that boundary by consolidating prose-only Markdown resources into one `AMP_REFERENCES.md` per skill while preserving script-addressed resources at their original paths. The Nix export check enforces the limit; do not publish an unconsolidated source copy directly.

Discover and prepare the requested Global Plugins repository with `amp plugins repositories`. Use the Global User Plugins repository for one user's projects and threads, or the Workspace Plugins repository when an administrator is publishing the collection for the workspace. Then export and inspect the result:

```bash
scripts/export-compound-engineering-amp-plugin.sh <global-plugins-checkout>
git -C <global-plugins-checkout> status --short
git -C <global-plugins-checkout> diff --stat
```

The exporter owns only the `ce/` directory carrying its `compound-engineering.lock.json`. It rejects an unmanaged `ce` directory or single-file plugin collision and preserves unrelated plugins. It does not clone, commit, or push.

After reviewing the generated plugin, commit it in the Global Plugins checkout and ask before pushing. A push publishes it for new Amp threads. Existing threads need their plugins reloaded.

An Amp maintainer can be asked to run the workflow with:

> Refresh the Compound Engineering `ce` plugin in the user's Global Plugins repository from Toolnix's pinned input. Reuse or prepare the requested Global Plugins checkout, run `scripts/export-compound-engineering-amp-plugin.sh`, verify that Amp loads all 33 `ce:*` skills, review and commit the generated plugin, and ask before pushing it. After an approved push, reload plugins in the current thread.

#### Prepare Matt Pocock's `mp` plugin alongside `ce`

Toolnix packages all 27 skills published in Matt Pocock's upstream plugin v1.2.3
from `agent-skills/vendor/mattpocock`. Both lockfiles pin the published
`lefant/agent-skills` source. The generated `matt-pocock.lock.json` records the
vendor revision and original upstream revision. Updating the snapshot requires
reviewing the renderer's explicit skill list and upstream revision too.
Local `path:` input overrides record the vendor revision as `unlocked`; use the
normal pinned build for publication.

```bash
nix --accept-flake-config build .#matt-pocock-amp-plugin --no-link
nix --accept-flake-config build \
  .#checks.x86_64-linux.matt-pocock-amp-plugin-export \
  .#checks.x86_64-linux.matt-pocock-agent-baseline --no-link
scripts/export-matt-pocock-amp-plugin.sh <global-plugins-checkout>
```

The exporter follows the CE convention: it replaces only an owned `mp/` directory,
rejects unmanaged/file/symlink collisions, and preserves other plugins. It does
not clone, commit, push, run skills, or rewrite the current project's configuration.
`--source <built-plugin>` skips the Nix build. All 79 upstream package files retain
their paths; the MIT license and two plugin metadata files make 82 files total,
below Amp's 200-file import limit. Supporting resources are byte-identical;
`SKILL.md` retains upstream frontmatter/body and adds Amp integration guidance.
Unlike CE, MP needs no Markdown resource consolidation.

The plugin registers `mp:<skill>` names, including `/mp:grill-me`, `/mp:tdd`, and
`/mp:ask-matt`. Each skill carries a complete internal-call mapping: resolve MP
slash commands, bare skill references, and Skill tool arguments within `mp`.
This is an instruction-level mapping, not an Amp alias; preserve paths, labels,
ticket types, and other non-invocation identifiers. Upstream `/clear` and
`/compact` are harness commands, not exported MP skills.

**Manual-only flags are not an Amp permission boundary.** All 16 upstream
`disable-model-invocation: true` flags are preserved. On Amp
`0.0.1790926488-g24b332`, local discovery listed those skills with descriptions,
and the model-facing skill tool successfully loaded `mp:grill-me` during a
read-only verification. The renderer adds manual-use guidance, but Amp did not
block that tool call. Do not rely on the flag to suppress model discovery or
enforce user-only execution. Recheck after Amp updates.

**Choose MP or CE per task**, for example “Use MP for this task; start with
`/mp:grill-me`.” Namespaces avoid name collisions but do not isolate triggers or
loaded workflow instructions. Compare the families in fresh threads. Preserve
the project's existing document ownership and approval rules. Explicitly request
`/mp:setup-matt-pocock-skills` if setup is wanted; review its proposed project
instruction, tracker, label, and domain-document changes before applying them.
Installation grants no tracker, credential, or publication authorization.

Use-time review points (installation executes none of these):

- `diagnosing-bugs/scripts/hitl-loop.template.sh` echoes captured observations.
  Never capture credentials or secrets with it; leave sign-in to the human.
- `wizard/template.sh` is an executable example, not a safe no-op: its sample
  stages request Stripe keys, write `.env`, and call `gh secret set`. Review
  generated stages, use ignored secret files, avoid logs/shell tracing of secrets,
  and obtain authorization for GitHub secret/variable writes. Syntax checks do
  not verify a generated wizard's safety.
- `improve-codebase-architecture/HTML-REPORT.md` loads
  `https://cdn.tailwindcss.com` and Mermaid from
  `https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs`.
  These are remote executable dependencies, not fully pinned offline assets.
  Review network/privacy requirements for reports or substitute approved local
  assets before opening them. No CDN code was executed during packaging tests.

Home Manager omits MP from both Amp-visible trees (`~/.agents/skills` and
`~/.config/amp/skills`) to avoid duplicate bare names. Claude, OpenCode, and Pi
retain the normal bare-name baseline; Codex receives MP explicitly under
`~/.codex/skills/matt-pocock`. Other baseline skills and CE remain unchanged.
The Amp plugin is deliberately not auto-installed by Home Manager. A project
`devenv` shell does not install skills or plugins either.

For a local loading proof, export to a temporary `.amp/plugins` directory, load
`mp/index.ts`, then use `amp skills list --json` and
`amp skill info mp:tdd --json`. Remove the generated local copy afterward rather
than committing a second source snapshot. Check bundled resources as well as
names. This verifies local loading, not hosted publication.

For availability across projects and orbs, discover the writable Personal/User
Plugins repository with `amp plugins repositories`, export into its canonical
checkout, and review the diff. **Ask before pushing to that repository.** A
published personal plugin becomes available to new threads; existing threads
need a plugin reload. Toolnix publication and plugin publication are separate
approval steps. Neither is performed by the export command.

### Build the Home Manager activation package

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

### Apply the Home Manager configuration locally

Build first:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

Then activate the result:

```bash
./result/activate
```

### Inspect recent changes while working

```bash
git status
git log --oneline -n 10
```

## Recommended workflow for repo changes

1. Read the current architecture and any active plan docs first.
2. Make small changes in either:
   - Home Manager host ownership, or
   - `devenv` shell behavior,
   but avoid mixing concerns unless the change requires both.
3. Verify with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
devenv shell -- true
```

4. Record notable behavior changes in `docs/devlog/`.
5. Commit in small steps.

## Typical change categories

### Host-state changes

Examples:

- adding or changing managed files under `$HOME`
- wiring new persistent agent config
- changing shared skill directory ownership
- updating shell/tmux/git/ssh host defaults

Primary file:

- `modules/home-manager/toolnix-host.nix`

Verify with:

```bash
nix build .#homeConfigurations.lefant-toolnix.activationPackage
```

### Project-shell changes

Examples:

- adding packages to the shell
- adjusting aliases or helper functions
- changing opinionated shell toggles
- restoring or adjusting opinionated zsh completion behavior
- adding optional `devenv` features

Primary files:

- `modules/devenv/default.nix`
- `modules/shared/opinionated-shell.nix`
- `modules/shared/agent-browser.nix`
- `modules/shared/browser-tools.nix`
- `modules/shared/required-baseline.nix`
- `modules/shared/agent-baseline.nix`

Verify with:

```bash
devenv shell -- true
scripts/check-opinionated-zsh.sh
scripts/check-opinionated-tmux.sh
```

### Architecture or boundary changes

Examples:

- changing ownership between Home Manager and `devenv`
- changing published flake/module interfaces
- changing repo-maintenance guidance

Update:

- `docs/reference/architecture.md`
- `README.md`
- relevant plan/devlog docs

## State locations

### Repo-managed sources

Tracked configuration sources live under:

- `agents/`
- `modules/`
- `home-manager/files/`
- `docs/`

### Persistent host state

Persistent host state lives under `$HOME`, including:

- `~/.claude/`
- `~/.codex/`
- `~/.config/opencode/`
- `~/.config/amp/`
- `~/.openclaw/`
- `~/.pi/agent/`
- `~/.agents/skills`

For current host-local `pi` model/backend usage, including Together-backed custom models and validated Fireworks opt-in models, see [`pi-model-backends.md`](pi-model-backends.md).

### Optional browser state

When `agent-browser` or `browserTools` is enabled, host-local browser runtime state lives under:

- `~/.agent-browser`

The current Toolnix integration uses the Nix-packaged `agent-browser` and Nix-managed Chromium, so normal first-run use does not require npm install state. Older hosts may still have cleanup-safe state from the previous lazy npm wrapper under:

- `~/.local/share/toolnix/agent-browser/npm-prefix`
- `~/.cache/toolnix-agent-browser/npm`

## Binary cache note

`toolnix` uses `github:numtide/llm-agents.nix` as a flake input for the tracked agent CLIs.

The repo publishes the Numtide cache requirement in `flake.nix` via flake `nixConfig` so direct commands such as wrapped-tool proofs can use it.

For direct use, prefer:

```bash
nix run --accept-flake-config github:lefant/toolnix#toolnix-pi
```

Important multi-user Nix note:

- on fresh exeuntu VMs with a Determinate multi-user Nix install, ordinary users are not trusted to add arbitrary substituters
- in that environment, flake `nixConfig` alone is not sufficient to trust `cache.numtide.com`
- add the Numtide cache to machine-local trusted Nix settings first, for example via `/etc/nix/nix.custom.conf`

For that environment, use machine-local settings such as:

```conf
extra-substituters = https://cache.numtide.com
extra-trusted-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

Important scope rule:

- direct use of `toolnix` can rely on the cache settings published by `toolnix`
- a downstream flake that imports `toolnix` should not assume those cache settings propagate automatically from the input
- any flake recipe that depends on `llm-agents.nix`, directly or transitively, must ensure the required cache settings in its own recipe or machine-local Nix config before expensive builds begin

Required cache settings:

```conf
extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

Keep the standard `cache.nixos.org` cache enabled as well.

For diagnostics, compare:

```bash
nix config show | rg 'substituters|trusted-substituters|trusted-public-keys|extra-substituters|extra-trusted-substituters|extra-trusted-public-keys'
nix run -L --accept-flake-config github:lefant/toolnix#toolnix-pi -- --help
```

A healthy cache path should show Nix copying from caches rather than building large dependency chains locally.

Related artifacts:

- [`../specs/llm-agents-cache-bootstrap.md`](../specs/llm-agents-cache-bootstrap.md)
- [`../plans/2026-04-05-exe-vm-bootstrap-proof.md`](../plans/2026-04-05-exe-vm-bootstrap-proof.md)

## Notes

- `.claude.json` is intentionally still a special-case activation merge.
- Historical devlogs may describe earlier states of the repo; prefer `architecture.md` for the current model.
- inventory/control-host wrappers remain opt-in behind `toolnix.enableHostControl`.
- `tmux-meta` is available by default because it does not depend on inventory-specific state.
