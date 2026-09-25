---
date: 2026-09-25
status: ✅ COMPLETED
---

# TypeSafe agent-skills update

Updated both Toolnix lockfiles to published agent-skills revision
[`d1041f0`](https://github.com/lefant/agent-skills/commit/d1041f025d65210d76b873d9e31bc18c74040cac).
The fetched source contains `vendor/typesafe-ai/typesafe-ai/SKILL.md` and its MIT
license. Existing vendor directory discovery includes the skill without module
changes. No other dependency nodes changed.

Verification passed:

- `nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage --no-link`
- `devenv shell -- true`
- `nix --accept-flake-config flake check --no-build --no-eval-cache`
- Both lockfiles contain identical agent-skills nodes at the published revision.
- The built Home Manager files contain byte-identical TypeSafe skill and license
  files under `.agents/skills`, `.claude/skills`, `.config/opencode/skills`,
  `.config/amp/skills`, and `.pi/agent/skills`.

Checks emitted warnings about restricted cache-key settings, an `options.json`
derivation lacking store-path context, unchecked custom flake outputs, and the
installed devenv version being newer than its locked input. All commands exited
successfully; unrelated pins and configuration were left unchanged.

Code review: skipped (mechanical diff). This is a dependency pin update with no
Toolnix code changes; lockfile scope and built skill contents were checked directly.

Delivery is local only. No push, PR, Home Manager activation, or deployment was
performed.
