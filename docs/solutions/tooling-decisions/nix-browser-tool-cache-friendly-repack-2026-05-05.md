---
title: Cache-Friendly Nix Repacking for Chromium-Bound Browser Tools
date: 2026-05-05
category: tooling-decisions
module: toolnix browser tools
problem_type: tooling_decision
component: tooling
severity: medium
applies_when:
  - "A cached upstream Nix package is almost correct but is wrapped to the wrong runtime dependency"
  - "A Toolnix option must align multiple browser-facing tools on one Chromium derivation"
  - "Rebuilding the upstream package locally would be expensive or likely to exhaust disk"
tags: [nix, agent-browser, chromium, browser-tools, cache, llm-agents, vhs]
---

# Cache-Friendly Nix Repacking for Chromium-Bound Browser Tools

## Context

Toolnix needed to replace the old lazy npm `agent-browser` wrapper with a Nix-managed `agent-browser` while adding a heavier `toolnix.browserTools.enable` bundle for `agent-browser`, `vhs`, and Chromium. The user specifically wanted both browser-facing tools to use Toolnix `pkgs.chromium`, not a separate Chromium from `llm-agents.nix`, and wanted browser tooling to remain opt-in.

The direct-looking Nix solution was to call the upstream `llm-agents.nix` `packages/agent-browser/package.nix` with Toolnix `pkgs` and `chromium = pkgs.chromium`. That proved too expensive on a small VM: it entered a local Rust/pnpm build of the `agent-browser` dashboard closure and failed with `ERR_PNPM_ENOSPC`. Session history shows the earlier state was host-native but lazy npm based, requiring `agent-browser install`; this work intentionally moved away from that model after the user asked whether Compound Engineering's `agent-browser` and `vhs` guidance could share one host Chromium (session history).

## Guidance

When an upstream Nix package is cached and functionally correct except for an embedded runtime path, prefer a small repack/wrapper derivation over a source rebuild if all of these are true:

- the upstream package output is available from a trusted cache;
- the package's runtime data can be copied into a new output;
- embedded references are deterministic and can be patched safely;
- the final output can be checked for absence of the unwanted dependency path;
- the public Toolnix contract is about runtime binding, not about rebuilding from source.

For the browser tools bundle, the pattern became:

```nix
upstreamAgentBrowserPackage =
  if llmAgentsPackages ? agent-browser
  then llmAgentsPackages.agent-browser
  else pkgs.callPackage "${llmAgentsPath}/packages/agent-browser/package.nix" { };

agentBrowserPackage = pkgs.stdenvNoCC.mkDerivation {
  pname = "agent-browser";
  version = upstreamAgentBrowserPackage.version or "0.26.0";
  nativeBuildInputs = [ pkgs.makeWrapper pkgs.python3 ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p "$out/bin"
    cp ${upstreamAgentBrowserPackage}/bin/.agent-browser-wrapped "$out/bin/.agent-browser-wrapped"
    cp -R ${upstreamAgentBrowserPackage}/share "$out/share"
    chmod u+w "$out/bin/.agent-browser-wrapped"
    chmod +x "$out/bin/.agent-browser-wrapped"

    python3 - <<'PY'
import os
from pathlib import Path
old = b"${upstreamAgentBrowserPackage}"
new = os.environ["out"].encode()
if len(old) != len(new):
    raise SystemExit(f"store path length mismatch: {len(old)} != {len(new)}")
path = Path(os.environ["out"]) / "bin/.agent-browser-wrapped"
data = path.read_bytes()
if old not in data:
    raise SystemExit("upstream package path not found in agent-browser binary")
path.write_bytes(data.replace(old, new))
PY

    makeWrapper "$out/bin/.agent-browser-wrapped" "$out/bin/agent-browser" \
      --set AGENT_BROWSER_EXECUTABLE_PATH ${lib.escapeShellArg chromiumExecutable}
  '';
};
```

Key details:

- Copy both the executable payload and `share/agent-browser` data, because `agent-browser skills path core` and `agent-browser skills get core` must resolve inside the final Toolnix output.
- Patch embedded references from the upstream output path to the new output path. Nix store paths have fixed length, so this is safe only while the old and new store paths have equal byte length; fail loudly otherwise.
- Wrap the copied executable with `AGENT_BROWSER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium`.
- Use `pkgs.vhs.override { chromium = pkgs.chromium; }` so `vhs` gets the same browser package through its nixpkgs wrapper.
- Keep `browserTools.packages` to the additional heavy bundle pieces (`vhs` and Chromium), and include `agent-browser` through an `agentBrowserEffective = agentBrowser.enable || browserTools.enable` composition gate to avoid duplicate package entries.

## Why This Matters

Rebuilding from the upstream package definition gave the cleanest dependency graph in theory, but it was operationally wrong for a constrained host: the local build tried to realize a large Rust/pnpm dependency graph and filled disk. Repacking the cached output preserved the user's important runtime invariant — Toolnix `agent-browser` uses Toolnix Chromium — while avoiding unnecessary local build pressure.

This also keeps Toolnix's published interface clean:

- `toolnix.agentBrowser.enable` stays narrow and now Nix-managed;
- `toolnix.browserTools.enable` becomes the heavy opt-in bundle;
- default consumers do not receive Chromium or `vhs`;
- Compound Engineering helper tools stay light;
- old npm prefix/cache state becomes cleanup-safe legacy state rather than active runtime state.

The trade-off is that binary repacking depends on upstream output layout. Mitigate that with explicit build-time checks, wrapper/path inspection, and runtime smoke tests.

## When to Apply

- Use this when a cached Nix package has the right executable and bundled data but is wrapped to a dependency from the wrong package set.
- Use this when forcing the package to rebuild with a different dependency would cause cache misses or local builds that are large relative to the host.
- Avoid this when the upstream package provides a supported override/overlay interface that can replace the runtime dependency without rebuilding the heavy parts.
- Avoid this when the binary embeds paths in variable-length or opaque formats that cannot be patched and verified deterministically.

## Examples

### Verify the final output does not keep the old Chromium

After building the Toolnix wrapper, inspect references and strings:

```bash
pkg=/nix/store/...-agent-browser-0.26.0
nix-store -q --references "$pkg" | rg 'chromium|agent-browser'
strings "$pkg/bin/agent-browser" "$pkg/bin/.agent-browser-wrapped" | rg 'chromium-147|old-upstream-agent-browser' || true
strings "$pkg/bin/agent-browser" | rg 'AGENT_BROWSER_EXECUTABLE_PATH|chromium-146'
```

The desired result is a reference to Toolnix `pkgs.chromium`, no reference to the upstream Chromium path, and a wrapper export similar to:

```bash
export AGENT_BROWSER_EXECUTABLE_PATH='/nix/store/...-chromium-146.0.7680.80/bin/chromium'
```

### Prove bundled share data and runtime behavior

Use a temporary home so the proof does not depend on or mutate durable browser state:

```bash
tmp_home=$(mktemp -d)
HOME="$tmp_home" agent-browser skills path core
HOME="$tmp_home" agent-browser open https://example.com
HOME="$tmp_home" agent-browser wait --load networkidle
HOME="$tmp_home" agent-browser get title
HOME="$tmp_home" agent-browser close --all
rm -rf "$tmp_home"
```

Expected proof points:

- `skills path core` points inside the Toolnix `agent-browser` output's `share/agent-browser/skill-data/core`.
- `get title` returns `Example Domain`.
- No `agent-browser install` or npm install step is needed.

### Keep evaluation checks cheap

Default flake checks should prove package selection and environment binding without realizing the full browser closure. Heavy wrapper/runtime proofs can remain targeted manual checks or non-default CI jobs when disk budget permits.

## Related

- `docs/devlog/2026-05-05-browser-tools.md` — implementation outcome, disk cleanup, and validation proof.
- `docs/plans/2026-05-05-001-feat-browser-tools-plan.md` — requirements and implementation plan.
- `docs/brainstorms/2026-05-05-browser-tools-requirements.md` — origin requirements.
- `docs/devlog/2026-03-28-agent-browser-opt-in-module.md` — historical lazy npm model superseded by this approach.
- `docs/devlog/2026-05-04-compound-engineering-helper-tools.md` — why `vhs` remains outside the default helper-tool bundle.
