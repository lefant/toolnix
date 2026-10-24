---
date: 2026-10-24
status: ✅ COMPLETED
---

# Refresh agent-skills documentation paths

Updated `agent-skills` through `nix flake update agent-skills` and
`devenv update agent-skills`. Both lockfiles now pin
[`38f16e15d6ec972b772a460bc6fd21407a24a5c9`](https://github.com/lefant/agent-skills/commit/38f16e15d6ec972b772a460bc6fd21407a24a5c9),
the fetched `origin/main` tip, instead of
[`ddc10f079e33701a6922a7ce0d97ef4978b23427`](https://github.com/lefant/agent-skills/commit/ddc10f079e33701a6922a7ce0d97ef4978b23427).
Unrelated lock entries are unchanged.

The upgrade supplies the documentation-path fixes and the new Ponytail and
Quint skills. Toolnix generates skill trees and plugin bundles from this input;
there is no bundled source copy to refresh. Advanced the MP renderer's reviewed
vendor-commit guard after confirming `vendor/mattpocock` is byte-for-byte
unchanged between these revisions. The guard remains enforced.

## Verification

- `nix --accept-flake-config flake check --no-eval-cache -L`: all Linux checks
  passed, including MP, Antithesis, CE, browser, and portable agent-profile checks.
- `nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage --no-link`:
  passed; no activation performed.
- `devenv shell -- true`: passed using devenv from the locked nixpkgs input.
- Pinned-source documentation-path tests: all four passed. Vendor-layout tests
  and validation passed, reporting 97 skills.
- Generated Home Manager skill links resolve to the new locked source for the
  affected documentation skills, Ponytail, and all three Quint skills.
- Both lock entries match exactly; all other entries are unchanged;
  `git diff --check` passed.
- Additional `flake check --all-systems --no-build --no-eval-cache` could not
  evaluate Darwin because the pinned devenv-nixpkgs import requires an invalid
  `devenv-nixpkgs-patched.drv` store path in this Linux orb. The same failure
  reproduces on unchanged Toolnix `origin/main`; it is not introduced by this
  update. Native Darwin execution was not tested.

Host activation and global skill/plugin publication remain separate operations.
