# Compound Engineering global Amp plugin export

## Outcome

Added a reproducible rendering and export path for publishing all 33 pinned Compound Engineering skills as one Amp directory plugin named `ce`.

The plugin exposes concise qualified names such as `ce:plan`, `ce:work`, and `ce:lfg`. It shortens only each bundled package's directory and frontmatter name. Discovery descriptions use the qualified cross-skill names, and every loaded `SKILL.md` explains how to map upstream cross-skill references to the `ce:` namespace. Upstream artifact metadata, configuration values, paths, scripts, and internal identifiers remain unchanged.

## Publication behavior

The `compound-engineering-amp-plugin` flake package contains the complete plugin, including its TypeScript entrypoint, bundled skills, upstream license, source revision, and name mapping manifest.

Amp imported items accept at most 200 files. The initial 403-file publication was present in the Personal Plugins Git repository but absent from Settings, plugin reloads, and fresh contexts without a load error. The renderer now consolidates prose-only Markdown references into one `AMP_REFERENCES.md` per skill while retaining script-addressed resources at their original paths. The resulting plugin contains 153 files. Its entrypoint also emits literal `registerSkill` paths for static discovery.

`scripts/export-compound-engineering-amp-plugin.sh` copies that package into an existing Amp Global User or Workspace Plugins repository checkout as `ce/`. It replaces only a prior Toolnix-managed `ce` directory, rejects unmanaged directory and single-file collisions, preserves unrelated plugins, and deliberately does not clone, commit, or push.

## Verification

- `nix --accept-flake-config build .#compound-engineering-amp-plugin --no-link` passed.
- `nix --accept-flake-config build .#checks.x86_64-linux.compound-engineering-amp-plugin-export --no-link` passed.
- The exporter check verified all 33 mappings, namespace guidance, preserved metadata and executable bits, repeated refreshes, unrelated-plugin preservation, and collision rejection.
- A project-local export loaded as an active Amp plugin. `amp skills list --json` reported exactly 33 `ce:*` skills with zero errors, including `ce:plan`, `ce:work`, and `ce:lfg`, and no `ce:ce-*` names.
- `amp skill info ce:plan --json` resolved the package and showed the qualified `ce:brainstorm` reference in its discovery description.
- The reduced plugin was pushed to a Personal Plugins repository and reloaded as active `amp-global-plugin:ce` with user scope and no error.
- A fresh CLI process reported all 33 `ce:*` skills with zero errors. `amp skill info` resolved `ce:plan`, `ce:work`, and `ce:compound`.
- `shellcheck scripts/export-compound-engineering-amp-plugin.sh` passed inside the declared devenv shell.
- `nix --accept-flake-config flake check --no-eval-cache` passed all flake checks.
- `devenv shell -- true` passed.

Expected Nix warnings remain for the client-specified trusted key and the existing `devenv-nixpkgs` import-from-derivation context. The installed devenv CLI also reports that it is newer than the locked devenv input; these warnings did not affect the checks.
