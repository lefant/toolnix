# Plan: fresh-environment bootstrap paths and credentials injection

## Date

2026-04-05

## Goal

Establish a durable bootstrap architecture for fresh environments, with clear proof procedures, explicit credential-injection modes, and a minimal public bootstrap entry path that hands off to Nix-managed `toolnix` setup.

Related artifacts:

- [`docs/specs/fresh-environment-bootstrap.md`](../specs/fresh-environment-bootstrap.md)
- [`docs/specs/llm-agents-cache-bootstrap.md`](../specs/llm-agents-cache-bootstrap.md)
- [`docs/plans/2026-04-05-exe-vm-bootstrap-proof.md`](2026-04-05-exe-vm-bootstrap-proof.md)
- [`docs/reference/credentials.md`](../reference/credentials.md)
- [`docs/reference/architecture.md`](../reference/architecture.md)

## Problem statement

`toolnix` can now be bootstrapped on a fresh exe.dev VM, but the end-to-end story still spans several concerns that should be tightened together:

- minimal machine bootstrap before Nix can take over
- cache prerequisites for `llm-agents`
- standalone versus control-host-assisted credential injection
- proof procedures for wrapped-tool and full-host setup
- maintainer guidance for re-running and evolving those proofs

The current pieces exist, but they need to be organized into one coherent bootstrap model.

## Desired end state

### 1. One documented bootstrap model with two credential-injection modes

Document one bootstrap model with two explicit modes:

- **standalone bootstrap**
  - public-only repo access
  - machine-local manual credential injection
  - suitable for a fresh machine with no control-host relationship
- **control-host-assisted bootstrap**
  - same declarative `toolnix` target state
  - credentials or local files may be injected through an existing control-host workflow
  - still no tracked secrets in repo state

### 2. Minimal pre-Nix bootstrap artifact

Provide a small tracked bootstrap artifact that does only the pre-Nix work needed to hand off to Nix-managed setup, for example:

- install Nix when missing
- write required machine-local Nix cache settings when the environment needs them
- invoke the appropriate `nix run ...` or standalone bootstrap flake path

This artifact should stay intentionally small and should not absorb host-state provisioning that belongs in Home Manager.

### 3. Acceptance-oriented proof procedures

Maintain proof procedures for both:

- direct wrapped-tool path
  - fast smoke test
- full host bootstrap path
  - persistent `$HOME` verification

Each procedure should define:

- machine preconditions
- commands to run
- expected cache signals
- expected installed files
- known manual credential steps

### 4. Maintainer re-test workflow

Document a maintainer workflow for:

- creating a fresh exe.dev VM
- applying the current proof path
- iterating on failures
- deleting proof VMs afterward
- recording proof outcomes in devlogs

## Proposed work breakdown

### Phase A — Documentation consolidation

- add architecture overview for bootstrap surfaces and current repos/components
- document credential-injection modes explicitly in `docs/reference/credentials.md`
- add a focused bootstrap/testing reference page that links the spec, cache proof, and maintainer workflow

### Phase B — Minimal bootstrap artifact

- create a tracked script or pasteable shell artifact for fresh-machine bootstrap
- keep it limited to:
  - Nix installation
  - cache setup prerequisite handling
  - handoff to `toolnix` bootstrap commands
- avoid duplicating Home Manager ownership logic inside the script

### Phase C — Proof recipes and acceptance checks

- codify one fast wrapped-tool proof
- codify one full host bootstrap proof
- ensure each proof has explicit acceptance checks and failure diagnostics

### Phase D — Control-host compatibility review

- compare standalone bootstrap versus control-host-assisted bootstrap
- identify which steps differ only in credential injection
- keep declarative target state shared between both paths

## Acceptance criteria for this plan

- bootstrap responsibilities are documented clearly enough that a maintainer can explain what happens before Nix, inside Nix, and after activation
- the credential reference explains standalone versus control-host-assisted injection without mixing secrets into repo state
- a minimal bootstrap artifact exists or is fully specified as the next concrete implementation target
- fresh-machine proof instructions are easy to rerun on a new exe.dev VM
- architecture docs include a diagram of the current repos and flake/module composition involved in bootstrap

## Risks and notes

- bootstrap scripts can grow imperatively unless their scope is kept narrow
- control-host workflows can accidentally become the assumed default unless standalone bootstrap remains first-class in the docs
- bootstrap proof speed depends strongly on binary-cache correctness, so cache guidance must stay attached to bootstrap docs rather than drifting into unrelated references
