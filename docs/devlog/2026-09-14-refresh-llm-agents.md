---
date: 2026-09-14
status: ✅ COMPLETED
---

# Refresh llm-agents

The host reported an outdated Amp client. Running `amp update` downloaded a
newer binary but left the older Nix-managed executable first on PATH.

Refreshed only `llm-agents` in `flake.lock` and `devenv.lock`, including its
transitive nixpkgs pin. Both now use upstream revision
`8789d35418faa994adf0f46b2e76933cf41a5854`.

Verification passed:

- `nix --accept-flake-config build .#homeConfigurations.lefant-toolnix.activationPackage --no-link`
- `devenv shell -- true`
- The refreshed Nix package's `amp --version` reports `0.0.1789329654-g2cdf19`.
- `git diff --check`

The packaged Amp release still predates `0.0.1789390780-g75f8bb`, which the
user downloaded manually. Refreshing the upstream pin does not guarantee
removal of the outdated warning. No host activation was performed; publishing
this change and updating the host's consuming configuration remain separate steps.
