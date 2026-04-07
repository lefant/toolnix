# fresh environment bootstrap

## Purpose

`toolnix` should support repeatable bootstrap of a fresh environment, especially a fresh exe.dev VM, with a clear separation between declarative toolnix state and machine-local credential injection. This spec defines the required behavior for bootstrap paths, credential ownership, and proof-oriented testing.

## Requirements

### Fresh environments SHALL have a minimal public bootstrap path

A fresh machine SHALL be bootstrappable with a minimal public bootstrap flow that installs Nix if needed and then hands off to Nix-managed `toolnix` setup.

**Scenarios:**
- GIVEN a fresh exe.dev VM with no prior Nix setup WHEN the documented bootstrap flow is followed THEN Nix is installed and the machine can begin a `toolnix` bootstrap without requiring access to an existing control host
- GIVEN a bootstrap initiated by another system without privileged GitHub credentials WHEN the documented path is followed THEN the bootstrap relies only on public GitHub flake refs and machine-local configuration

### Bootstrap paths SHALL separate declarative setup from credentials injection

Bootstrap flows SHALL distinguish between declarative `toolnix` state and machine-local credential injection.

**Scenarios:**
- GIVEN a fresh machine bootstrapped from a control host WHEN credentials are injected through that host's workflow THEN the resulting machine still keeps secrets outside tracked repo state
- GIVEN a fresh machine bootstrapped without a control host WHEN the operator performs manual login or local env-file setup THEN the bootstrap still produces the same declarative `toolnix` state while leaving credentials machine-local

### Credential injection modes SHOULD be documented explicitly

The system SHOULD document the distinct credential injection modes used by bootstrap from a control host versus standalone first-run bootstrap.

**Scenarios:**
- GIVEN a maintainer reads the credentials reference WHEN they are deciding how to bootstrap a new machine THEN they can distinguish between control-host-assisted injection and standalone manual injection
- GIVEN a maintainer is testing bootstrap behavior WHEN they follow the docs THEN they know which steps are expected to remain manual and machine-local

### Fresh-machine bootstrap SHALL have an executable proof procedure

A fresh-machine bootstrap path SHALL be described by a repeatable proof procedure with explicit acceptance checks.

**Scenarios:**
- GIVEN a maintainer creates a fresh exe.dev VM WHEN they execute the proof procedure THEN they can verify cache configuration, successful Nix-managed bootstrap, and expected persistent host files
- GIVEN the proof procedure fails WHEN the maintainer inspects the acceptance checks THEN the failing stage is clear enough to drive iteration and re-test on a fresh VM

### Testing guidance SHOULD cover both wrapped-tool and full-host bootstrap paths

Bootstrap documentation SHOULD cover both the direct wrapped-tool proof path and the standalone full-host bootstrap path.

**Scenarios:**
- GIVEN a maintainer wants the fastest smoke test WHEN they follow the docs THEN they can run a wrapped-tool proof such as `toolnix-pi`
- GIVEN a maintainer wants full host provisioning proof WHEN they follow the docs THEN they can run the standalone Home Manager bootstrap path and verify installed host files under `$HOME`

## Open Questions

- [ ] Should the minimal public bootstrap script itself live in this repo as a tracked executable artifact?
- [ ] Should a future control-host path be represented as a separate spec or as scenarios within this one?
- [ ] Should bootstrap acceptance tests eventually run automatically outside manual exe.dev proof sessions?
