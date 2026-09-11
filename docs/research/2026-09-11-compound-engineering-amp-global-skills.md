# Compound Engineering global Amp skills research

## Goal

Publish Toolnix's pinned Compound Engineering skill rendering through Amp's Global User or Workspace Skills repositories so the skills are available across projects, threads, clients, and orbs.

## Current boundaries

- Toolnix owns the pinned `EveryInc/compound-engineering-plugin` input and target renderers.
- `agent-skills` intentionally contains portable skill sources only and does not own the Compound Engineering bundle.
- Home Manager exposes the rendered Compound skills to machine-local Amp through `~/.config/amp/skills`.
- Amp Global Skills repositories require one complete skill package per top-level directory. Published text resources are synchronized by Amp and do not depend on a Nix store in the destination environment.

The pinned upstream distribution currently contains 33 end-user skills: 32 `ce-*` packages and `lfg`. The generated collection contains about 400 text files and no binary resources.

## Chosen boundary

Toolnix should provide a deterministic export artifact and a local export command. The command accepts an existing Global Skills repository checkout as its destination and updates only the Compound Engineering packages it owns.

The exporter must not clone, commit, or push. Those operations affect account or workspace state and remain an explicit Amp or human publishing workflow.

## Safety and update ownership

The destination needs a manifest that records the upstream revision and the exact managed skill names. On refresh, the exporter may replace or remove only names from that manifest. A first export must reject an existing destination skill with the same name instead of assuming ownership.

Each exported skill must carry the upstream MIT license so the package remains self-contained when Amp serves or shares it independently.

## Validation

The export should fail before changing the destination when:

- a directory name does not match its `SKILL.md` frontmatter name;
- a skill package contains a non-UTF-8 regular file;
- the generated collection has no skills or lacks the upstream license;
- the destination contains an unmanaged name collision; or
- an existing ownership manifest is malformed or belongs to another source.
