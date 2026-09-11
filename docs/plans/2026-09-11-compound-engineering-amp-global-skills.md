# Compound Engineering global Amp skills export

## Goal

Add a reproducible Toolnix workflow for refreshing Compound Engineering skills into an existing Amp Global User or Workspace Skills repository checkout without performing publication automatically.

## Plan

1. Expose an Amp-ready, self-contained Compound Engineering skill collection as a flake package.
2. Add an exporter that stages and validates the collection, protects unmanaged destination names, and updates only manifest-owned skills.
3. Add Nix checks for the Amp package shape and exporter behavior, including collision protection and unrelated-skill preservation.
4. Document the generic Amp review, commit, push, and reload workflow using terms such as “the user” rather than account-specific names or URLs.
5. Run the targeted checks, full flake check, and shell smoke test, then record the outcome in a devlog.

## Non-goals

- Do not clone, commit, or push a Global Skills repository from the exporter.
- Do not publish skills as part of orb setup or Home Manager activation.
- Do not move Compound Engineering into `agent-skills`.
- Do not encode a specific Amp username, workspace, repository URL, or checkout path.

## Acceptance checks

```bash
shellcheck scripts/export-compound-engineering-amp-skills.sh
nix --accept-flake-config build .#compound-engineering-amp-skills --no-link
nix --accept-flake-config build .#checks.x86_64-linux.compound-engineering-amp-export --no-link
nix --accept-flake-config flake check --no-eval-cache
devenv shell -- true
```
