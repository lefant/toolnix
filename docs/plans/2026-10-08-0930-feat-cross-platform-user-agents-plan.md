---
title: Shared user agent environment on Linux and macOS
date: 2026-10-08
type: feat
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-brainstorm
execution: code
---

# Shared user agent environment on Linux and macOS

## Goal Capsule

**Objective:** Lefant has the same Nix-managed coding-agent versions, personal preferences, skills, and supported integrations on existing Toolnix Linux VMs and the main user account of an Apple Silicon Mac.

**Means:** Move the Mac's host composition into `lefant/nix-darwin`, retaining a separate reusable Arkion module, then integrate the extracted Toolnix user-level agent configuration through Home Manager.

**Product authority:** Decisions agreed in [the source brainstorm](https://ampcode.com/threads/T-01a11557-64d2-75d6-accd-d2360e19811e). The Product Contract defines scope; the Planning Contract defines execution boundaries.

**Open blockers:** No product decisions block planning. Darwin packaging, configuration ownership, and runner access need technical verification before implementation and activation.

## Product Contract

### Summary

Provide one shared, user-scoped environment for five coding-agent CLIs and their configuration on Linux and macOS.
Include browser automation with a platform-appropriate browser, and deliver the working setup on Lefant's Mac.
Preserve existing Linux host behavior while moving it onto the shared implementation.

### Problem Frame

The Mac currently obtains agent CLIs independently of Toolnix, which permits version and configuration drift.
Toolnix's published per-system outputs currently target x86_64-linux, and its full Home Manager profile also owns shell, Git, SSH, and other host configuration.
Reusing personal agent preferences should not require adopting that whole host profile or importing its disposable-VM trust assumptions.

### Requirements

**Packages and personal configuration**

- R1. Install Claude Code, Codex, Pi, Amp CLI, and OpenCode together for the selected user; the first version needs no individual agent enable switches.
- R2. Use the same pinned CLI versions across supported Linux and Apple Silicon macOS hosts consuming the same Toolnix revision, with no silent platform-specific version fallback.
- R3. Manage persistent personal preferences through Nix and supported CLI configuration files, including model preferences and shared instructions; credentials, session history, and other mutable runtime state remain local and unmanaged.
- R4. Install the full shared collection from the pinned `lefant/agent-skills` source and applicable local integrations, including Compound Engineering and other existing supported plugin collections, without adding exclusion controls in this version.
- R5. Respect each agent's supported discovery mechanisms rather than assuming every plugin works in every agent.
- R6. Install Amp CLI and its settings while relying on normal signed-in operation for account-published plugin collections, avoiding redundant local copies of the same collections.

**Scope and migration**

- R7. Scope package profile installation and agent configuration to Lefant's actual macOS user account, leaving other accounts and unrelated shell, Git, SSH, and desktop application configuration untouched.
- R8. Use the existing nix-darwin configuration as the initial unified activation path; avoiding administrator prompts is desirable but not required.
- R9. Reuse the extracted agent implementation from the existing Linux host profile without changing its observable behavior, apart from the separately authorized Beads removal.
- R10. Keep VM-specific permission bypasses, onboarding acknowledgements, MCP policy, and trusted-project paths outside the portable personal defaults; the Mac must not inherit those settings accidentally.
- R11. On adoption, back up conflicting unmanaged configuration before replacing it with declared configuration and notify the user where the private local backups are stored; preserve previous backups and do not treat already-managed files as unmanaged conflicts.
- R12. Subsequent activations apply declared settings without migrating or overwriting authentication, session history, or other agent-owned runtime data.

**Browser automation**

- R13. Make `agent-browser` and a compatible browser available to the Mac user and actual agent runner through the existing opt-in browser capability, including a Darwin installation path rather than requiring a manual browser prerequisite.
- R14. Keep automation browser state separate from the everyday browser and never automatically import its cookies, logins, or profile.
- R15. Default to fresh browser sessions, with state retained across commands within a run but no automatic restoration from earlier runs.
- R16. Support explicit named persistence across runs independently of temporary session naming, while keeping saved browser authentication local and outside Nix and Git.
- R17. Keep VNC and remote-display tooling separate from basic browser automation and out of the Mac installation.

**Delivery**

- R18. Build and verify the shared setup, integrate it into `lefant/nix-darwin`, and apply it on the actual Mac, including checks from the Amp runner environment.
- R19. Commit and push coherent, checked changes in `lefant/toolnix` and `lefant/nix-darwin`; inspect automatic effects before pushing and retain human checkpoints for administrator credentials.
- R20. Verify Linux preservation without activating shared Linux VMs as part of this delivery.

**Host ownership prerequisite**

- R21. Move the actual `Fabians-MacBook-Pro` host composition from `skyqraft/mac-dev-setup` into `lefant/nix-darwin`, where it composes personal settings, the reusable Arkion company module, and eventually Toolnix agents.
- R22. Keep reusable company settings in the Arkion repository without a dependency on Lefant's personal modules, allowing colleagues to consume them independently.
- R23. Verify equivalent effective host configuration before and after the ownership migration, before adding the agent setup; preserve a recoverable previous host entrypoint until the new one is verified.
- R24. Limit company-repository changes to the host/module separation and necessary local commits; do not publish company content or rename repositories as part of this work.

### Key Decisions

- **One personal setup, not a separate Mac preference set.** Governs R2–R5. (session-settled: user-directed — chosen over host-specific preferences: versions, models, skills, and plugins should match.)
- **All five CLIs together.** Governs R1. (session-settled: user-directed — chosen over individual enable switches: all five are wanted immediately.)
- **Full collection without exclusion controls.** Governs R4. (session-settled: user-directed — chosen over configurable subsets: exclusions are not needed initially.)
- **Preserve Linux behavior through extraction.** Governs R9–R10. (session-settled: user-approved — chosen over parallel implementations: Linux adoption should be a behavioral no-op.)
- **Backup and adopt.** Governs R11–R12. (session-settled: user-directed — chosen over blocking on conflicts: replace existing configuration with a backup and notification.)
- **Fresh browser sessions by default.** Governs R14–R16. (session-settled: user-directed — chosen over persistent-by-default automation: persistence should be an opt-in.)
- **Signed-in Amp operation.** Governs R6. (session-settled: user-directed — chosen over offline plugin duplication: model-provider access already requires connectivity.)
- **Deliver on the Mac, not only as an example.** Governs R18–R20. (session-settled: user-directed — chosen over module-only delivery: apply, verify, commit, and push.)
- **Personal repo owns the machine; company repo owns reusable company settings.** Governs R21–R24. (session-settled: user-approved — chosen over a third host repository or full consolidation: allow future company co-maintenance without company configuration depending on personal settings.)

### Key Flows

1. **Adopt on the Mac:** Resolve the actual user and existing configuration owners, migrate and verify host composition, then build the agent configuration, back up unmanaged conflicts, activate with any required human administrator step, and verify from the runner. Covers R7–R8, R11–R12, R18, R21–R24.
2. **Update personal defaults:** Change the Nix-declared preferences or input pins, build both platform configurations, and activate the Mac through its unified configuration. Linux rollout remains separate. Covers R2–R3, R9, R20.
3. **Automate a browser:** Start a fresh isolated run, use the same session for subsequent commands, and close it; request named persistence only when cross-run state is intended. Covers R13–R17.

### Acceptance Examples

- AE1. Given the same Toolnix revision on Linux and Mac, all five CLI versions match and their declared model preferences and intended skill/plugin collections agree. Agent-specific discovery layouts may differ. Covers R1–R6.
- AE2. Given an existing Mac settings file and local login state, adoption preserves a private backup, installs the declared settings, and leaves login state and history unchanged; a repeat activation preserves the original backup. Covers R11–R12.
- AE3. Given the Linux host configuration before extraction, comparison after extraction shows unchanged versions, settings, skills, aliases, trust behavior, and runtime locations, excluding the independent Beads removal. Store paths need not be identical. Covers R9–R10, R20.
- AE4. From the actual Mac Amp runner, `agent-browser` launches its installed browser and produces a snapshot and screenshot without an ad hoc `npx` installation or interactive-shell-only PATH adjustment. Covers R13, R18.
- AE5. A new fresh browser run does not inherit a prior run's login, while an explicitly persistent named run restores supported saved state; neither changes the everyday browser profile. Covers R14–R16.
- AE6. After activation, all five CLIs launch and discover their intended configuration and integrations; authenticated live checks use user-provided local logins and report unavailable credentials as blockers, not successful verification. Covers R1–R6, R18.
- AE7. Before agent integration, the personal repo's host entrypoint produces equivalent effective host settings and package versions to the original company-repo entrypoint, and the Arkion module can be consumed without importing Lefant's personal configuration. Covers R21–R23.

### Scope Boundaries

GUI agent applications and personal desktop-browser configuration are excluded, except installing the browser required by R13.
Plugin publication to Amp account repositories, offline Amp plugin support, Mac VNC tooling, per-agent switches, and skill exclusion controls are excluded.
There is no authorization to delete user data, activate Linux VMs, merge pull requests, or manually trigger deployments.
Host/module separation under R21–R24 is included; repository renaming, a third host repository, and company-repository publication are excluded.
The first supported Mac target is Apple Silicon; Intel Mac support is not implied.

<!-- ce-section: work-relationships -->
### How This Work Fits Together

This artifact owns the cross-platform user agent setup and its actual Mac adoption.

- **Coordinate with Beads removal:** [The separate removal thread](https://ampcode.com/threads/T-01a1167a-3d81-7499-8895-cf0fad7103b1) reported a local checked commit on `remove-beads`, not pushed or transferred here at report time. Inspect its current delivery state before integration; do not duplicate or assume the change is already on the remote.
- **Integrate with the Mac configuration:** [The Mac setup thread](https://ampcode.com/threads/T-01a10c67-6753-7022-8e1c-e7524b741f1f) reports that `skyqraft/mac-dev-setup` currently composes `Fabians-MacBook-Pro` from its company/host modules and a locked local-Git input of `lefant/nix-darwin`. R21–R24 reverse that ownership before agent integration. The personal repo's `docs/CodingAgents.md` describes the initial CLI setup; reconcile package ownership rather than installing duplicate copies.
- **Use runner evidence without changing marimo:** [The browser-workaround thread](https://ampcode.com/threads/T-01a1168b-33d0-7464-85de-d6378b231d86) reported successful ephemeral Nix Node plus `npx agent-browser` use. That does not establish reproducible browser packaging or default runner PATH availability.

### Outstanding Questions

**Resolve Before Planning:** None.

**Research questions and execution gates:** The Planning Contract below resolves the design choices and assigns remaining runtime checks to implementation units.

- Confirm the Darwin browser package, executable path, and lifecycle supported by the pinned `agent-browser` version, including clean-session and persistence semantics.
- Identify which agent configuration files can remain immutable and which need supported mutable-state handling without violating R3 and R12.
- Verify Amp CLI account-plugin discovery and local skill discovery to implement R6 without hiding nonduplicated skills.
- Inventory current plugin installers and update behavior per agent; determine how Nix owns supported local integrations under R4–R5.
- Confirm the Mac runner, checkout, user short name, home directory, existing worktree changes, and administrator activation mechanism; do not infer them from a display name.
- Establish platform build capability and regression comparisons, including the patched nixpkgs evaluation step that required Darwin execution during initial investigation.
- Reconcile both repositories' current remote state and agreed working branches before checked pushes, including Beads removal status.
- Inspect the company checkout's current module exports and lock graph; choose a pinned company-module input in the personal repo that works with its current local-only status without publishing company content or creating a dependency cycle.
- Identify host-equivalence comparisons and the recoverable old entrypoint for R23, keeping existing dependency revisions stable during ownership migration.

### Evidence and Limitations

Relevant existing owners are `flake.nix`, `flake-parts/wrapped-tools.nix`, `flake-parts/public-outputs.nix`, `modules/shared/agent-baseline.nix`, `internal/profiles/home-manager/core.nix`, and `modules/shared/browser-tools.nix`.
The current readiness contract is `docs/specs/toolnix-agent-readiness.md`.
Initial investigation evaluated upstream Apple Silicon derivations for the five agent CLIs, but did not build or run the full Toolnix setup on macOS.
The existing `toolnix.agentBrowser.enable` flag is opt-in; its current implementation assumes Nix Chromium's Linux-style executable path.
No implementation or host activation is represented as complete by this requirements artifact.

## Planning Contract

Product Contract unchanged, except relabeling its research-question list to point to the resolutions below. R1–R24 and AE1–AE7 retain their meaning.

### Approach and Technical Decisions

- KTD1. Export `homeManagerModules.agents` using the existing feature registry and a new agent-only profile. Move agent packages, static files, skills, and applicable integrations out of the host core; the existing full profile imports it rather than duplicating declarations. Covers R1–R7, R9.
- KTD2. Separate portable agent preferences from a Linux-host compatibility policy. The old host explicitly retains its aliases, trusted paths, Claude runtime seeding, and MCP policy; the new agent-only export does not seed bypass acknowledgements. Characterize Linux outputs before refactoring. Covers R9–R10.
- KTD3. Keep one package source: Toolnix's pinned `llm-agents` packages. Remove the Mac's old system-level declarations for the three replaced CLIs when user-level ownership takes effect. Do not change package pins merely to perform extraction. Covers R1–R3.
- KTD4. Keep static settings declarative, but classify each file before migration. Preserve the Linux `.claude.json` merge in its compatibility policy; do not generalize it to all settings. If a CLI rewrites a declarative file, use its supported override/configuration mechanism or a narrowly scoped generated mutable copy, never overwrite a mixed credential file. Covers R3, R10–R12.
- KTD5. Implement adoption as a pre-link, scoped backup step for the exact new module-owned targets. Remove unconditional `force` from the new portable ownership path. Use private, unique backup locations and notifications; recognize managed store links, detect dangling/unmanaged symlinks, and never traverse their targets. Do not apply a global backup policy to unrelated Home Manager files. Covers R11–R12.
- KTD6. Preserve the current cached Linux browser repack. On Darwin, use the pinned upstream CLI directly with a platform-specific wrapper around a fixed-output Chrome for Testing browser package. Prefer `playwright-driver.components.chromium` if present in the locked nixpkgs; otherwise add a narrowly pinned mac-arm64 archive derivation rather than a broad nixpkgs update. No runtime browser download. Covers R13, R17.
- KTD7. Do not set a global persistent profile or auto-restore default. Document and verify the pinned CLI's isolated temporary sessions and explicit named persistence; add a small wrapper only if native flags cannot meet R14–R16. Session names alone must not imply restoration.
- KTD8. Move host composition into the personal flake, consuming a committed company-module input. Initially retain the company checkout as a locked local-Git input because it has no publication authorization. Remove its dependency on the personal flake from the new company export to avoid a cycle. Retain the old host via its recorded commit/generation, not a circular compatibility import. Covers R21–R24.
- KTD9. Preserve existing agent-specific skill layouts and generated integrations. Inventory signed-in Amp discovery before removing any local assets; filter only confirmed account-provided duplicates, and retain nonduplicated local skills. Do not publish plugins. Covers R4–R6.

### High-Level Technical Design

These sketches describe responsibility boundaries, not prescribed function signatures.

```diagram
lefant/nix-darwin: Mac host
  ├── personal modules
  ├── pinned Arkion module ── company settings only
  └── Home Manager user ── Toolnix agents profile
                              ├── five pinned CLIs
Toolnix Linux full profile ────┤── preferences and integrations
  └── VM compatibility policy └── optional platform browser
```

```diagram
Adoption target
  ├── absent / already managed ──────────────▶ link declared file
  ├── unmanaged file, directory, or symlink ─▶ private unique backup
  │                                           └── success ─▶ link
  │                                           └── failure ─▶ stop
  └── credential / history / unowned path ───▶ never modify
```

| Browser mode | Commands in the same run | Later run |
|---|---|---|
| Fresh or named temporary | Reuse isolated live session | No saved state loaded |
| Explicit named persistence | Reuse isolated live session | Restore that named automation state |
| Everyday browser | Not attached or imported | Unchanged |

### Execution Gates and Risks

The plan is ready to implement, but no activation is allowed until its relevant build and migration gates pass.
Mac paths and repository state come from thread reports, not a current checkout inspection; inspect them on the authorized runner before editing.
The actual account reported is `lefant`, host key `Fabians-MacBook-Pro`; neither is to be inferred from a display name.
Keep company file contents, browser credentials, and backup contents out of public Toolnix docs and logs.

For backups, successful Home Manager generation rollback does not itself restore adopted unmanaged files. Record both the prior generation and a private path-to-backup manifest; recovery must refuse to overwrite newer user edits without review.
For browser packaging, modern nixpkgs exposes an Apple Silicon Playwright Chromium component, but availability and the app-bundle executable path in Toolnix's locked nixpkgs remain an implementation smoke-test gate.
The pinned upstream agent-browser is 0.38.1; current orb CLI documentation is not a substitute for that version's flags.
If runtime findings require changed user behavior or a version divergence, stop and revise the affected requirement rather than silently weakening it.

## Implementation Units

### U1. Capture baselines and reconcile source state

**Requirements:** R2, R9, R19–R20, R23. **Dependencies:** None.
Inspect local/remote state in all three repositories, the separate Beads delivery, and the Mac runner's allowed checkouts. Reconcile the planning commits without overwriting concurrent work. Record current Linux generated packages, environment, managed-file contents, skills, and VM trust behavior; record the actual Mac host inputs, effective settings, current generation, and file owners privately.
**Files:** existing `flake-parts/features/agent-baseline.nix`; new `scripts/check-agent-profile.py` for normalized public comparison data; Mac host files identified in U2.
**Tests:** comparison rejects a changed model, missing skill, changed trust path, or missing CLI; ignores only store-prefix/generation metadata that cannot affect behavior. Never collect auth contents. Beads is the sole preauthorized behavioral exclusion.
**Execution note:** Establish characterization coverage before moving code. Readiness evidence is separate from production activation.

### U2. Reverse Mac host ownership without behavior changes

**Requirements:** R21–R24, AE7. **Dependencies:** U1.
In `lefant/nix-darwin`, extend `flake.nix` and add `hosts/fabians-macbook-pro.nix` from the inspected host-owned settings. In `skyqraft/mac-dev-setup`, keep `nix/arkion.nix` reusable and adjust `flake.nix` exports so the company input does not import Lefant. Preserve dependency revisions where possible; update each affected `flake.lock` deliberately. Record the old entrypoint and commit before changing its composition.
**Tests:** new `scripts/check-host-equivalence.nix` in the personal repo compares selected effective host options and package versions against the old host; independently evaluate the company module with a minimal non-Lefant host fixture. Compare system derivations where feasible, explaining benign source/revision metadata differences. Build the actual host before agent integration.
**Gate:** no unrelated company or personal settings may change; do not publish the company repo or copy its reusable contents into the personal repo.

### U3. Extract the shared agent module with Linux compatibility

**Requirements:** R1–R6, R9–R10, AE1, AE3. **Dependencies:** U1.
Create `internal/profiles/home-manager/agents.nix`, wire it through `flake-parts/profiles/home-manager.nix` and `flake-parts/public-outputs.nix`, and reduce `internal/profiles/home-manager/core.nix` to host ownership plus explicit compatibility policy. Keep `modules/shared/agent-baseline.nix` as package/skill data owner and reuse `modules/shared/compound-engineering.nix`. Split VM-only template fields where needed without changing their Linux values.
**Tests:** new `flake-parts/checks/agent-profile.nix`, imported through `flake-parts/default.nix`, evaluates agent-only and full-profile fixtures. Verify all five packages, expected files/skills, no shell/Git/SSH files in the agent-only fixture, no Mac VM bypass/trust seeds, and unchanged Linux characterization outputs. Retain existing Compound, MP, and Antithesis checks.
**Execution note:** Commit the behavior-preserving extraction before adding portable behavior or changing conflict handling.

### U4. Add safe portable configuration adoption

**Requirements:** R3, R7, R11–R12, AE2. **Dependencies:** U3.
Add the scoped pre-link backup behavior to `internal/profiles/home-manager/agents.nix`; use a dedicated helper only if required for testability. Keep existing managed Linux targets on their compatibility path. Notifications expose backup locations, not contents. A failed backup stops activation before that target is replaced; partial completion is recoverable from the manifest.
**Tests:** new `scripts/tests/test-agent-adoption.sh`, wired into the profile checks, uses a disposable HOME. Exercise absent target, regular-file conflict, directory conflict, dangling symlink, foreign symlink, existing managed symlink, repeated activation, second unmanaged conflict, backup failure, and unrelated credential/history sentinels. Require private permissions, unique retained backups, untouched symlink destinations, and no lost original on failure.

### U5. Add Apple Silicon outputs and browser packaging

**Requirements:** R2, R13–R17, AE4–AE5. **Dependencies:** U3.
Extend `flake.nix` systems with `aarch64-darwin`; audit per-system checks so Linux-only checks are guarded, not disabled globally. Update `modules/shared/browser-tools.nix` to select browser/package paths by platform and avoid the Linux-only upstream wrapped-file assumption on Darwin. Keep full browser-tools/HITL separate. Ensure `flake-parts/wrapped-tools.nix` still builds where exported.
**Tests:** new `flake-parts/checks/browser-platform.nix` verifies platform package composition and executable selection. New `scripts/check-agent-browser-sessions.sh` exercises a disposable local fixture: same-run state survives, fresh runs lose it, explicit persistence restores it, parallel session names remain isolated, and an everyday-profile sentinel is untouched. Execute builds and browser smoke checks on both target platforms; macOS executable paths with spaces must work.
**Gate:** confirm cached/fixed browser source and pinned CLI semantics before activation; do not rely on `npx`, globally installed Chrome, or `agent-browser install`.

### U6. Integrate the user environment and activate the Mac

**Requirements:** R1–R8, R11–R19, AE1–AE2, AE4–AE6. **Dependencies:** U2, U4, U5.
In `lefant/nix-darwin/flake.nix`, pin Toolnix and compatible Home Manager inputs; configure the user module in `hosts/fabians-macbook-pro.nix`. Remove superseded CLI declarations from `config/lefant-nix-darwin.nix`. Enable basic agent-browser, not VNC. Check downstream Numtide cache configuration without assuming input-level nixConfig propagates.
Resolve runtime PATH for the actual Amp runner using its existing launch environment; do not introduce unrelated global shell files or restart unrelated workloads. Build, inspect the scoped backup inventory, and activate with the human supplying any required administrator credentials. Keep live account sign-in human-controlled.
**Tests:** new personal-repo `scripts/check-coding-agents.sh` checks paths, versions, configuration and discovery without printing secrets. Run from a terminal and the actual runner, compare five CLI versions to the Linux baseline, verify account/local plugin duplication, and execute U5 browser checks. Report missing authenticated access as blocked. Verify no second old system CLI shadows a user-profile binary.

### U7. Document, publish, and record delivery evidence

**Requirements:** R18–R20, R24. **Dependencies:** U6 for completion; the checked Toolnix source checkpoint must be published before U6 pins its final revision. Publication of that checkpoint does not imply Mac activation or U7 completion.
Update `README.md`, `docs/reference/architecture.md`, `docs/specs/toolnix-agent-readiness.md`, and the personal repo's `docs/CodingAgents.md`; record outcomes in `docs/devlog/`. Document activation ownership, backup recovery, browser modes, and boundaries between account plugins and local integrations.
Inspect push effects, publish checked Toolnix changes, then pin the published revision in the personal configuration and verify the final locked Mac build before its checked push. Keep company-module commits local. Never claim a local override demonstrates the final published pin.
**Verification:** compare recorded deployed revisions with committed locks, report pushes and Mac activation separately, and confirm no Linux VM activation or company publication occurred.

## Verification Contract

| Surface | Required evidence | Failure disposition |
|---|---|---|
| Linux extraction | Normalized before/after comparison; existing Home Manager, Pi and relevant flake checks; devenv smoke | Fix regression before portable behavior lands |
| Mac host migration | Old/new host comparison and actual host build; independent company-module evaluation | Do not add agents until equivalent |
| File adoption | Disposable-HOME conflict/failure/repeat tests and protected runtime sentinels | Do not activate if backup or ownership check fails |
| Darwin packages | Native Mac builds and five version checks against pinned Linux versions | No silent fallback to different versions |
| Browser | Native launch, snapshot, inspected screenshot, fresh/persistent isolation checks | Do not count package evaluation as runtime proof |
| Agent discovery | Actual runner's binary paths and skill/plugin inventory; signed-in checks where available | Missing auth is blocked, not passed |
| Delivery | Published personal/Toolnix revisions, locked deployed input, Mac generation, local company commit | State partial delivery honestly |

Use existing Home Manager activation-package builds and `devenv shell -- true` checks plus the new focused checks above. Test artifacts use disposable data; no test reads or exports personal cookie stores. Build failures caused by cache trust, unavailable native builders, or disk pressure must be distinguished from implementation defects.

## Definition of Done

- All R1–R24 are covered by the implementation and recorded evidence, including actual Mac activation and runner verification.
- Linux behavior is preserved without activating shared VMs; the intentional Beads change is reconciled separately.
- The personal repo owns the host and imports the company module without a dependency cycle or company-content publication.
- Credentials/history remain intact, private backups are recoverable, and browser profiles are isolated.
- Final published pins are verified, the two authorized repositories are pushed, and any remaining human/authentication blocker is reported rather than called complete.

## Appendix

### Research Sources and Confidence

Local findings are grounded in the owners listed above and `docs/solutions/tooling-decisions/nix-browser-tool-cache-friendly-repack-2026-05-05.md`, `docs/devlog/2026-04-16-openclaw-runtime-config-out-of-home-manager.md`, and `docs/devlog/2026-04-29-compound-engineering-codex-default.md`.
The pinned [upstream agent-browser derivation](https://github.com/numtide/llm-agents.nix/blob/af40d966859ec4075ecc172dbb39e53f474dc5d9/packages/agent-browser/package.nix) wraps Chromium only on Linux; Darwin needs its own browser binding.
The [nixpkgs Playwright Chromium source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/web/playwright/chromium.nix) provides the candidate Darwin fixed-output archive; this research references upstream master, so U5 must check the actual locked package before using it.
The [Home Manager Darwin integration](https://github.com/nix-community/home-manager/blob/master/nix-darwin/default.nix) and [file collision checks](https://github.com/nix-community/home-manager/blob/master/modules/files/check-link-targets.sh) inform adoption design; implementation must use the pinned versions, particularly for unmanaged symlinks and repeated backup collisions.

Confidence is high in module ownership and migration sequencing, moderate in platform packaging and live discovery until native execution. Those uncertainties are bounded U5/U6 gates, not claims of completed verification. No production changes, builds, or runtime tests were performed during this planning pass.
