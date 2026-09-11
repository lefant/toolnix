---
title: Bundle Large Skill Collections as One Amp Plugin
date: 2026-09-11
category: tooling-decisions
module: Compound Engineering Amp integration
problem_type: tooling_decision
component: tooling
severity: medium
applies_when:
  - "A related skill collection is too large for the hosted Personal Skills profile"
  - "Amp skills need a stable qualified namespace across projects and threads"
  - "Upstream skill names and cross-skill references do not match the desired Amp namespace"
related_components:
  - Amp Global Plugins
  - Compound Engineering skill renderer
  - Nix flake packages and checks
  - Global Plugin repository exporter
tags:
  - amp
  - compound-engineering
  - plugins
  - skills
  - namespaces
  - nix
---

# Bundle Large Skill Collections as One Amp Plugin

## Context

Toolnix exposes the 33 skills from its pinned Compound Engineering input to several agents. Publishing those packages individually as Amp Personal Skills would consume 33 hosted skill entries and can exceed the user's Personal Skills profile capacity when combined with an existing collection.

Amp directory plugins provide a better boundary for a related collection. A plugin can register many bundled skill directories with `amp.registerSkill`, while the hosted profile manages the collection as one plugin. Amp names each registered skill `<plugin-name>:<skill-name>`.

The desired Toolnix interface is `ce:plan`, `ce:work`, and `ce:lfg`, rather than `compound-engineering:ce-plan` or `ce:ce-plan`. That requires an Amp-specific adapter because the upstream package names are primarily `ce-*` and upstream instructions refer to those names directly.

## Decision

Render the pinned Compound Engineering input as one Amp directory plugin named `ce`:

```text
ce/
├── index.ts
├── compound-engineering.lock.json
├── LICENSE
└── skills/
    ├── plan/
    ├── work/
    ├── lfg/
    └── ...
```

Strip one leading `ce-` from each bundled directory and its `SKILL.md` frontmatter name. Keep upstream names without that prefix, such as `lfg`, unchanged. The plugin namespace then produces the public names automatically:

```text
ce-plan  -> ce:plan
ce-work  -> ce:work
lfg      -> ce:lfg
```

Do not globally replace upstream skill names throughout package resources. The same strings can be artifact metadata, configuration values, paths, script arguments, filenames, or run identifiers. Instead:

1. qualify known skill references in discovery descriptions;
2. inject a namespace rule into each rendered `SKILL.md` that maps semantic cross-skill invocations from `ce-foo` to `ce:foo`; and
3. explicitly preserve upstream spelling for non-invocation contracts.

Record the pinned upstream revision and complete upstream-to-bundled mapping in `compound-engineering.lock.json`. Include the upstream license in the generated plugin.

Amp rejects imported plugin items containing more than 200 files. The upstream collection renders to 403 files without adaptation, so Toolnix consolidates prose-only Markdown resources into one `AMP_REFERENCES.md` per skill. It rewrites instructions to name the consolidated file and original-path section. Markdown files addressed by scripts remain at their original paths. This preserves all 33 workflows and executable resources while reducing the published plugin to 153 files.

## Publication Boundary

Keep rendering, repository export, and publication separate:

```bash
nix --accept-flake-config build .#compound-engineering-amp-plugin --no-link
scripts/export-compound-engineering-amp-plugin.sh <global-plugins-checkout>
```

The exporter updates only a prior Toolnix-managed `ce/` directory. It rejects unmanaged directory, single-file, and symlink collisions, and preserves unrelated plugins. It does not clone, commit, or push the hosted repository.

A Git push publishes the repository contents. No repository manifest, import command, or separate Settings registration is required. Verify activation in a fresh Amp process, not only with the repository checkout or a project-local plugin proof. In the first Toolnix publication, the hosted repository contained a 403-file `ce` plugin, while both a plugin reload and a fresh thread silently omitted it. `amp plugins update ce` exposed the otherwise-unreported cause: `The imported item contains too many files to update safely.` Reducing the rendered item below the 200-file boundary made the existing personal plugin appear and activate automatically.

## Verification

Test the renderer and exporter independently of hosted activation:

```bash
nix --accept-flake-config build .#compound-engineering-amp-plugin --no-link
nix --accept-flake-config build \
  .#checks.x86_64-linux.compound-engineering-amp-plugin-export --no-link
nix --accept-flake-config flake check --no-eval-cache
devenv shell -- shellcheck scripts/export-compound-engineering-amp-plugin.sh
```

Load an export from `.amp/plugins/ce/` for a deterministic project-local integration proof. Confirm that Amp reports exactly 33 `ce:*` entries, including `ce:plan`, `ce:work`, and `ce:lfg`, and no `ce:ce-*` entry. Inspect representative packages with `amp skill info` to check discovery references and the injected namespace rule.

After publishing globally, use a fresh thread as a separate acceptance check. The plugin is globally active only when that thread can discover and load representative `ce:*` skills.

## Why This Works

The directory plugin uses Amp's native qualified-name contract rather than adding aliases or wrappers around individual skills. Toolnix owns only the platform adaptation: shortening local package names, supplying cross-skill namespace semantics, preserving upstream resource contracts, and rendering a reproducible artifact from the Nix-pinned source.

Separating the deterministic build proof from hosted activation also prevents a false positive. A project-local plugin can prove the generated TypeScript and skill packages are valid, while a fresh global process proves that the hosted profile actually exposes the published plugin. Enforcing the 200-file ceiling in the Nix check prevents valid local exports that Amp's hosted index silently omits.

## Related

- `docs/research/2026-09-11-compound-engineering-amp-global-plugin.md` — Amp naming and cross-skill reference analysis.
- `docs/plans/2026-09-11-compound-engineering-amp-global-plugin.md` — implementation sequence and acceptance criteria.
- `docs/devlog/2026-09-11-compound-engineering-amp-global-plugin.md` — implementation and local integration results.
- `docs/reference/maintaining-toolnix.md` — rendering and publication runbook.
