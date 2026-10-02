---
date: 2026-10-02
status: ✅ COMPLETED
---

# Antithesis Amp plugin publication

## Outcome

Published the 14-skill `antithesis` directory plugin using the same renderer,
guarded exporter, and Home Manager filtering pattern as MP. The user authorized
shipping after the vendor snapshot was published by the
[agent-skills thread](https://ampcode.com/threads/T-01a0fc2e-ce55-701b-8ad2-2758926db91b).
Both `flake.lock` and `devenv.lock` now pin
[the published vendor commit](https://github.com/lefant/agent-skills/commit/ab5f3072557c8ac72f3965e09a38f181fe4f9bcc).
The implementation and pins were pushed to Toolnix `origin/main`, and the
regenerated plugin was SSH-signed with Amp's managed signing helper and pushed
to the Personal/User Plugins repository. No host activation or deployment ran.

The full `nix --accept-flake-config flake check -L` passed without overrides.
The published plugin matches the pinned Nix build byte-for-byte and records the
published vendor revision, not `unlocked`. A plugin reload succeeded; fresh Amp
discovery reported 14 Antithesis, 33 CE, and 27 MP skills with no errors.
New threads load it automatically; existing threads require a plugin reload.

## Source and packaging

- Upstream: [Antithesis snapshot](https://github.com/antithesishq/antithesis-skills/commit/1fd8470d36a9629a75bda4619a5589d679a40d7c).
- Vendor layout: `vendor/antithesishq/antithesis-<name>`.
- Preserved 107 upstream package files and executable bits, Apache-2.0 license,
  and vendor `SOURCE.md` provenance/safety review.
- Generated plugin: 111 files, including `index.ts` and `antithesis.lock.json`.
- Amp uses short names such as `antithesis:research`; only the frontmatter name
  changes, followed by an explicit Toolnix modification notice and invocation
  mapping. Resource files and upstream bodies remain unchanged.
- The generic `agent-browser` skill and CLI remain separate. Cross-skill
  resource references resolve against the named companion skill.
- Bare Antithesis skills are filtered from both Amp discovery trees; Claude,
  OpenCode, Pi, and Codex retain access using upstream names.

## Verification

Transferred the full source archive from the agent-skills thread and verified
SHA256 `d53cacb1efc22738e1b0c0674e97b09af7e3ebcccfb880a547e1256f6c68de4a`.
An independent byte/mode comparison in this Toolnix thread matched all 107
skill-package files to the cached upstream checkout.

Checks used a local source override at `/tmp/toolnix-antithesis-agent-skills`:

```bash
nix --accept-flake-config flake check path:. \
  --override-input agent-skills path:/tmp/toolnix-antithesis-agent-skills \
  --no-write-lock-file -L
```

Passed the full flake check, including Antithesis package/export and Home Manager
checks plus existing MP/CE checks. Nix emitted restricted-key and existing
derivation-context/unchecked-output warnings. The packaging test reported:

```text
PASS: 14 skills, 111 files, resource/mode fidelity, namespace mapping, guarded export
```

`amp plugins list` loaded the plugin in a disposable test workspace;
`amp skills list --json` reported 14 `antithesis:*` skills and no errors.
`amp skill info antithesis:query-logs --json` resolved its installed path, and
local and cross-skill assets were readable there. `bash -n` and `git diff --check`
passed. No authenticated Antithesis workflow, container build, cluster action,
mutation sweep, or paid run was executed.

Review: inspected the diff and package fidelity in-thread. The harness restricts
delegation for routine self-review, so no independent multi-reviewer receipt is
claimed. Code review: skipped (ce-code-review unavailable) for its independent
reviewer workflow; manual inspection and executed checks cover this checkpoint.
The simplification pass retained separate MP/Antithesis exporters to preserve
the established per-collection boundary without refactoring the shipped MP path.

## Operational cautions retained

Mutation forks include gitignored files, so `.gitignore` does not protect
secrets from copying/build contexts. Browser URL-path checks do not authenticate
the tenant origin. Debugger `authorizeAll` can approve remote commands and is
not a substitute for human consent. Keep cookies, signed URLs, logs, and debug
output private. The added guidance calls out these risks and preserves approval
gates for uploads, paid runs, cluster changes, and destructive cleanup.
