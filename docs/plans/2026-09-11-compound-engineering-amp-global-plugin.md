# Compound Engineering global Amp plugin export

## Goal

Add a reproducible Toolnix workflow for publishing the pinned Compound Engineering collection as one Amp Global Plugin named `ce`, exposing 33 bundled skills under concise names such as `ce:plan`.

## Plan

1. Add an Amp-specific renderer that copies the existing Amp-ready skill collection into a directory plugin, shortens local skill names, injects the cross-skill namespace rule, and writes the plugin entrypoint and source metadata.
2. Expose the rendered directory as the `compound-engineering-amp-plugin` flake package.
3. Add a local-only exporter for an existing Global User or Workspace Plugins checkout, with unmanaged-collision protection.
4. Add Nix checks for renderer semantics, exporter safety, and all 33 registered names.
5. Load an exported project-local proof through Amp, inspect representative bundled skills, run the full repository checks, and document the publishing runbook and outcome.

## Non-goals

- Do not rename or alter the existing bare-skill package and Global Skills exporter.
- Do not rewrite upstream artifact metadata, configuration values, paths, or internal run labels.
- Do not clone, commit, or push a Global Plugins repository from the exporter.
- Do not encode a specific Amp username, workspace, repository URL, or checkout path.

## Acceptance checks

```bash
shellcheck scripts/export-compound-engineering-amp-plugin.sh
nix --accept-flake-config build .#compound-engineering-amp-plugin --no-link
nix --accept-flake-config build .#checks.x86_64-linux.compound-engineering-amp-plugin-export --no-link
nix --accept-flake-config flake check --no-eval-cache
devenv shell -- true
```
