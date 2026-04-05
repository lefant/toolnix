## Summary

Documented and proved the `llm-agents` cache prerequisite for `toolnix`, added flake-level cache publication, fixed the exported Home Manager module so downstream flake consumers receive the required `toolnix` inputs, and updated the locked `llm-agents` input to a buildable revision.

## What changed

Changed:

- `flake.nix`
- `flake.lock`
- `README.md`
- `flake-parts/public-outputs.nix`
- `docs/specs/llm-agents-cache-bootstrap.md`
- `docs/plans/2026-04-05-exe-vm-bootstrap-proof.md`
- `docs/reference/maintaining-toolnix.md`

Behavior/documentation updates:

- `toolnix` now publishes the Numtide cache via flake `nixConfig`
- docs now state the downstream rule explicitly: any flake recipe that depends on `llm-agents.nix`, directly or through `toolnix`, must ensure the required cache settings before heavy builds
- docs now capture the Determinate multi-user Nix gotcha on fresh exeuntu VMs
- the proof plan now uses machine-local Nix cache config plus `home-manager switch -b backup`

Exported-module fix:

- `homeManagerModules.default` now injects the same `toolnix` input set that the internal self-hosted path already had
- this removed the downstream failure where `agent-baseline.nix` fell back to `builtins.getFlake` on an unlocked store path during standalone Home Manager bootstrap

`llm-agents` update:

- `fb1dfb5960aa4b8a91995f8f99ec2452e5052dbe`
- -> `c9e352e53c5164b68dd05acf5a87d5798b6aa003`

## Proof notes

Fresh exe.dev proof VMs used during iteration:

- `toolnix-cache-proof1`
- `toolnix-cache-proof2`
- `toolnix-cache-proof3`
- `toolnix-cache-proof4`
- `toolnix-cache-proof5`

Key failures found during proofing:

1. Flake cache settings alone were ignored on fresh Determinate multi-user Nix installs because the ordinary user was not trusted to add arbitrary substituters.
2. The standalone Home Manager bootstrap failed because the exported module path did not inject `toolnix` inputs for downstream consumers.
3. The older locked `llm-agents` revision referenced a broken `claude-code` artifact URL.
4. The first standalone Home Manager switch would clobber existing VM dotfiles such as `~/.gitconfig` unless backup mode was used.
5. Machine-local trust alone was not enough for the Home Manager proof path; the Numtide cache also had to be present in machine-local `substituters`, not only `trusted-substituters`.

Final passing proof on `toolnix-cache-proof5` used:

```conf
extra-substituters = https://cache.numtide.com
extra-trusted-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

and then:

```bash
nix run -L --accept-flake-config github:lefant/toolnix#toolnix-pi -- --help
nix run --accept-flake-config github:nix-community/home-manager -- switch -b backup --flake ~/.local/share/toolnix-bootstrap#bootstrap
```

Proof signals captured during that iteration:

- direct wrapped `pi` logs showed repeated `copying path ... from 'https://cache.numtide.com'`
- the bootstrap path fetched `codex-0.118.0` from `https://cache.numtide.com`
- after cache configuration was corrected, the bootstrap reduced to the expected small Home Manager derivation builds plus activation
- final activation installed:
  - `~/.claude/settings.json`
  - `~/.claude/skills`
  - `~/.pi/agent/settings.json`

All temporary proof VMs were deleted after recording the result.

## Why

This repo now has an explicit spec and a worked fresh-machine proof for the cache prerequisite that `llm-agents` imposes on `toolnix`. That prevents fresh exe.dev bootstrap attempts from silently falling back to large source builds and makes the downstream rule visible to future flake consumers.

## Notes

- the direct wrapped-tool path and the standalone bootstrap flake have different cache behavior surfaces; both needed to be tested
- on fresh exeuntu VMs, machine-local `/etc/nix/nix.custom.conf` settings were required even though `toolnix` now publishes flake `nixConfig`
- backup mode was necessary for standalone Home Manager activation because the base VM image already ships some user dotfiles
