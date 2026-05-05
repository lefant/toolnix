# Browser tools bundle

## Summary

Started migrating Toolnix browser automation from the old lazy npm `agent-browser` wrapper to Nix-managed browser tooling.

The new intended model is:

- `toolnix.agentBrowser.enable = true` provides Nix-packaged `agent-browser`
- `toolnix.browserTools.enable = true` provides the full browser automation/demo bundle
- both `agent-browser` and `vhs` use Toolnix `pkgs.chromium`
- `vhs` and Chromium remain out of the default Compound Engineering helper-tool bundle

## Changes

- Added `modules/shared/browser-tools.nix` to centralize browser package construction.
- Replaced `modules/shared/agent-browser.nix` with a Nix-packaged adapter instead of the lazy npm wrapper.
- Repacked the cached `llm-agents.nix` `agent-browser` executable instead of rebuilding the Rust/pnpm package locally; the wrapper patches the embedded share path and sets `AGENT_BROWSER_EXECUTABLE_PATH` to Toolnix `pkgs.chromium`.
- Added `flake-parts/features/browser-tools.nix` with Home Manager and `devenv` options.
- Wired browser-tools options into Home Manager and `devenv` profile imports.
- Updated host and project profile composition so `browserTools` implies `agentBrowser` behavior.
- Updated README and reference docs to remove normal first-run `agent-browser install` guidance.
- Added browser-tool requirements and implementation plan docs.

## Validation

Completed:

```bash
nix flake check --no-build --show-trace
nix build .#checks.x86_64-linux.browser-tools-packages --no-link --show-trace
nix build .#homeConfigurations.lefant-toolnix.activationPackage --no-link --show-trace
devenv shell -- true
```

After cleaning disk pressure, completed targeted package realization using substituters where available:

```bash
nix build --impure --expr '<browserTools.agentBrowserPackage>' --no-link --print-out-paths --option fallback false --max-jobs 1
nix build --impure --expr '<browserTools.vhsPackage>' --no-link --print-out-paths --option fallback false
```

Confirmed:

- `agent-browser --version` reports `0.26.0`
- `agent-browser skills path core` resolves to the Toolnix output's bundled share tree
- ordinary runtime proof works with temporary state: `agent-browser open https://example.com`, `wait --load networkidle`, `get title`, and `close --all`
- the Toolnix `agent-browser` wrapper references Toolnix `pkgs.chromium`
- the Toolnix `agent-browser` output no longer references the upstream `llm-agents.nix` Chromium path
- the `vhs` wrapper references Toolnix `pkgs.chromium` on `PATH`

Attempted targeted wrapper validation while developing:

```bash
nix build .#checks.x86_64-linux.browser-tools-wrappers --no-link --show-trace
```

That earlier build reached package realization but failed with `ERR_PNPM_ENOSPC` while building the rebased `agent-browser` dashboard dependency closure. The retained implementation avoids that local rebuild by repacking the cached upstream executable and patching it to Toolnix paths. The heavy wrapper check was not kept as a default flake check; the retained `browser-tools-packages` check validates package selection and Chromium env binding without realizing the browser package closure.

## Notes

Rebinding the upstream `llm-agents.nix` `agent-browser` package definition to Toolnix `pkgs.chromium` required a local Rust/pnpm build and hit disk pressure on the current VM. The implementation now uses the prebuilt `llm-agents.packages.*.agent-browser` executable as a cache-friendly source, copies its bundled skills/share data, patches embedded paths to the new output, and wraps it with Toolnix `pkgs.chromium`.

Old lazy-wrapper state paths are no longer used by Toolnix, but existing hosts may still have cleanup-safe leftovers under:

- `~/.local/share/toolnix/agent-browser/npm-prefix`
- `~/.cache/toolnix-agent-browser/npm`

The durable runtime state path remains:

- `~/.agent-browser`

## Follow-up

- Consider adding a non-default realization check for wrapper/binding proof if CI has enough browser-closure budget.
- Consider an upstream override/overlay request to make Chromium replacement cleaner than binary repacking.
