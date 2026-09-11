# Compound Engineering global Amp skills export

## Outcome

Added a reproducible export path from Toolnix's pinned Compound Engineering input to an existing Amp Global User or Workspace Skills repository checkout.

The new `compound-engineering-amp-skills` flake package contains the 33 distributed upstream skills, the pinned upstream revision, and the upstream MIT license. The export script dereferences Nix-store links, preserves executable scripts, makes the copied files writable, and puts the license in every exported skill package.

The exporter deliberately does not clone, commit, or push. Amp or the user performs those shared-state operations after reviewing the Global Skills repository diff.

## Safety behavior

`scripts/export-compound-engineering-amp-skills.sh` records ownership in `compound-engineering.lock.json`. A later refresh replaces or removes only names from that manifest and preserves unrelated destination skills. A first export fails before changing the destination if one of the generated names already exists without being manifest-owned.

Before writing the destination, the exporter verifies that:

- every package has `SKILL.md`;
- every directory name matches the skill's frontmatter name;
- names satisfy Amp's skill-name format;
- all regular files are UTF-8 text;
- no symbolic links remain; and
- the source contains a valid pinned revision and upstream license.

## Verification

- `nix --accept-flake-config build .#compound-engineering-amp-skills --no-link` passed.
- `nix --accept-flake-config build .#checks.x86_64-linux.compound-engineering-amp-export --no-link` passed.
- The export check verified 33 skills, license inclusion, executable preservation, repeat refreshes, stale managed-skill removal, unrelated-skill preservation, and unmanaged-collision rejection.
- An end-to-end export using the default flake-build path passed. `amp skill list --json` discovered all 33 exported skills with no errors.
- `nix --accept-flake-config flake check --no-eval-cache` passed all flake checks.
- `shellcheck scripts/export-compound-engineering-amp-skills.sh` passed inside the declared devenv shell.
- `devenv shell -- true` passed.

Expected Nix warnings remain for the client-specified trusted key and the existing `devenv-nixpkgs` import-from-derivation context. The installed devenv CLI also reports that it is newer than the locked devenv input; these warnings did not affect the checks.
