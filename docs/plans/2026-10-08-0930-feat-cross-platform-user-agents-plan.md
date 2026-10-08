---
title: Shared user agent environment on Linux and macOS
date: 2026-10-08
type: feat
artifact_contract: ce-unified-plan/v1
artifact_readiness: requirements-only
product_contract_source: ce-brainstorm
execution: code
---

# Shared user agent environment on Linux and macOS

## Goal Capsule

**Objective:** Lefant has the same Nix-managed coding-agent versions, personal preferences, skills, and supported integrations on existing Toolnix Linux VMs and the main user account of an Apple Silicon Mac.

**Means:** Move the Mac's host composition into `lefant/nix-darwin`, retaining a separate reusable Arkion module, then integrate the extracted Toolnix user-level agent configuration through Home Manager.

**Product authority:** Decisions agreed in [the source brainstorm](https://ampcode.com/threads/T-01a11557-64d2-75d6-accd-d2360e19811e). This artifact defines requirements, not an executable implementation plan.

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

**Deferred to Planning:**

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
