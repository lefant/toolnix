# Pi prebuilt distributions and eMudhra TLS rejection

Investigation date: 2026-10-25. This is a historical research snapshot, not a
package-selection change or rollout approval.

## Conclusion

The latest official standalone Pi release inspected, **1.4.0**, does not already
contain the fixed Bun runtime. Its Linux x64, Linux ARM64, and Apple Silicon
archives contain **Bun 1.3.14**. The x64 binary accepts seven of the 14 live
incident endpoints, including a No-CT endpoint.

A supported distribution that avoids compiling Pi is available:
**`@earendil-works/pi-coding-agent@1.4.0` under explicitly pinned Node 22.23.4**.
Both the official Node binary and the exact cached Toolnix-pinned Nixpkgs Node
22.23.4 output reject all 14 endpoints with `CERT_REVOKED`, through both `fetch`
and `node:https`. Healthy controls return HTTP 200.

The existing llm-agents Pi recipe has a `useBun = false` branch that can assemble
that npm distribution. It still needs Linux native-library fixup before it can
be treated as a complete Toolnix replacement. No such replacement was built,
selected, published, or activated during this investigation.

## Scope and source state

The requesting [security-update thread](https://ampcode.com/threads/T-01a16d53-4e4e-70cc-88d7-8dde455d3cfe)
reported an unpublished local `security/update-flake-inputs` HEAD of
`930eb82b562b64229645ea6834cca67e4c9205d5`. That state was not available in this
research checkout and was not treated as `origin/main`.

The supplied pins were:

- llm-agents:
  [`53a2d94ce3b88753200be9a0549d8978b031fa60`](https://github.com/numtide/llm-agents.nix/commit/53a2d94ce3b88753200be9a0549d8978b031fa60).
- Root Nixpkgs:
  [`17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09`](https://github.com/NixOS/nixpkgs/commit/17dd0b7a41bb7107ea33f30d869f3f4e8f09fc09).
- llm-agents' own locked Nixpkgs:
  [`f20cd90e28fe0403873f473b29e42662cd86e8c4`](https://github.com/NixOS/nixpkgs/commit/f20cd90e28fe0403873f473b29e42662cd86e8c4).
  Its package outputs must not be conflated with outputs from the root pin.

The source thread reported that its original Pi 1.4.0 Nix build embedded Bun
1.4.2 and accepted incident TLS; its replacement compiled with verified official
Bun 1.4.4 archives rejected all 14 endpoints with `CERT_REVOKED`, with an HTTP 200
healthy control. Those are **source-thread observations**, not builds or probes
repeated here. The absence of substitutes for that custom output says nothing
about whether upstream release binaries exist.

This investigation used isolated prebuilt downloads and cache substitutes on
x86_64 Linux. No credentials, authenticated model calls, source builds, package
selection changes, or host activation were used. Disposable probe installations
were removed afterward.

## Official standalone release artifacts

[Pi v1.4.0](https://github.com/earendil-works/pi/releases/tag/v1.4.0) was published
on 2026-10-21. Each filename below is relative to
`https://github.com/earendil-works/pi/releases/download/v1.4.0/`.

| Artifact | Compressed bytes | SHA256 | Runtime inspection |
| --- | ---: | --- | --- |
| `pi-linux-x64.tar.gz` | 42,645,744 | `f2e4e4329603223d03260cdb8bd5033dbdc1f73ba58ab8939db2e56546e115d2` | Executed: Bun 1.3.14 |
| `pi-linux-arm64.tar.gz` | 42,745,801 | `fa5829c7ef83ffeaebba015715c8306220f89b2aa8a00154efbba98dd5440156` | ARM ELF inspected: Bun 1.3.14, build `0d9b296a` |
| `pi-darwin-arm64.tar.gz` | 31,098,931 | `79d9979d76a2a5adb7c28e27e9b44629928ccd0dc9fbb6ae7217860bd5e8be5d` | ARM Mach-O inspected: Bun 1.3.14, build `0d9b296a` |

All three downloaded archives matched both `SHA256SUMS` and GitHub API asset
digests. Linux x64's embedded runtime was queried directly:

```bash
env -i HOME="$isolated_home" PATH=/usr/bin:/bin BUN_BE_BUN=1 \
  /absolute/path/to/extracted/pi/pi --eval \
  'console.log(JSON.stringify(process.versions))'
```

It reported `bun: 1.3.14`, Node compatibility version `24.3.0`, and BoringSSL
revision `0c5fce43b7ed5eb6001487ee48ac65766f5ddcd1`. The compatibility Node version
is not a separately running Node runtime. ARM binaries were not executed;
their embedded runtime strings are weaker evidence than an executed query.

The release layout includes the executable, `package.json`, themes, assets,
photon WASM, export-HTML data, docs, examples, and platform-native helpers. An
eventual Nix repack must retain these assets and handle Linux ELF/native-library
paths or Darwin signing as appropriate. Merely fetching `pi` is insufficient.

### Release channels and alternatives

- Upstream [PR #11319](https://github.com/earendil-works/pi/pull/11319), merged on
  2026-10-23, changes the standalone build workflow from Bun 1.3.14 to 1.4.4.
  Its author reports local tests on six platforms. That is not evidence of a
  subsequently published release artifact.
- The newest inspected [Build Binaries run](https://github.com/earendil-works/pi/actions/runs/39686887346)
  remained the 2026-10-21 v1.4.0 build. Its release-assets artifact is another
  container for that build, not a newer fixed channel.
- No current public prerelease/nightly alternative was found in the release
  listing or documented installation routes. npm dist-tags were only
  `latest = 1.4.0` and `legacy-node20 = 0.74.2`; the latter is not a verified
  security alternative and was not tested.
- The official `pi.dev/install.sh` route installs npm Pi, not a newer embedded
  Bun binary. It uses pinned dependency-install manifests and can provision
  Node. Its standalone Node fallback resolves `latest-v22.x`. The documented
  minimum Node version is 22.19.0, which by itself is not a security guarantee.
- Upstream documents `github:earendil-works/pi/stable`, version-tagged Nix
  references, and `main`. At inspection, `stable` pointed at the
  [v1.4.0 commit](https://github.com/earendil-works/pi/commit/4a080252f06caf63a525d7873c5d94d3c23887e0).
  Its Nix recipe builds workspace packages from source using Node 22. No
  published binary-cache configuration was found in its flake or Nix workflow;
  this was not established as a no-build substitute. Its platform declarations
  include both Linux architectures and Apple Silicon, plus Intel macOS.
- No independently fixed Homebrew/mise distribution was established. References
  to Homebrew in the installer concern obtaining Node; changing installers is
  not proof that the Pi runtime changed.

## TLS probe method and results

The endpoint list came from the 14 PEM filenames in the advisory's
[`chains.zip`](https://emudhra.we-have-a-problem.com/chains.zip), including both
No-CT variants. The README distinguishes the normal and AAA-cross-signed chains.
Each filename, without `.pem`, became an HTTPS hostname.

For each runtime the probe performed an unauthenticated GET using both global
`fetch` and `node:https`, with default certificate validation and a 15-second
timeout. Fetch redirects were disabled. The probe used `env -i`, an isolated
HOME, and no model-provider credentials. Negative endpoints and positive
controls used the same runtime/environment. All results below were decisive TLS
errors or HTTP responses, not timeouts.

Healthy controls were `https://emudhra.we-have-a-problem.com/` and
`https://example.com/`. **Both returned HTTP 200 under both APIs in every run.**

| Exact candidate | Incident outcomes per API |
| --- | --- |
| Official Pi 1.4.0, embedded Bun 1.3.14 | Seven HTTP 200 responses; seven AAA variants rejected with `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` |
| Official Node 22.23.4, OpenSSL 3.5.9 | All 14 rejected with `CERT_REVOKED` |
| Root-pinned cached Nix Node 22.23.4, OpenSSL 3.5.9 | All 14 rejected with `CERT_REVOKED` |
| Same cached Nix Node 22.23.4 with system extra CAs | All 14 rejected with `CERT_REVOKED` |
| Official Node 24.21.0, OpenSSL 3.5.8 | Seven HTTP 200 responses; seven AAA variants rejected with issuer-chain errors |
| Root-pinned cached Nix Node 24.21.0, OpenSSL 3.5.9 | All 14 rejected with issuer-chain errors |
| Same cached Nix Node 24.21.0 with system extra CAs | All 14 rejected with issuer-chain errors |
| Orb's existing Node 26.12.1, OpenSSL 3.5.9 | All 14 rejected with `CERT_REVOKED` |

System-extra-CA runs set
`NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt`. That does not establish
behavior with arbitrary custom trust stores. In the Bun and official Node 24
runs, the accepted set includes `dv-g3b-noct-emudhra.we-have-a-problem.com`.

The Nix Node 24 result is important contradictory evidence: **that exact build
was not demonstrated vulnerable** despite the official binary with the same
Node version accepting seven endpoints. Its issuer-chain rejection was not
established to have the same cause or robustness as Node 22's explicit
`CERT_REVOKED` rejection. Do not infer the cause from the version label or from
the different OpenSSL versions alone. Node 22.23.4 is the clearer verified
candidate, and matches the installer's supported LTS fallback.

Official Node archives used for executed probes:

| Artifact | SHA256 |
| --- | --- |
| `https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz` | `1805bcd35e6815559bd2eb97db438d3fdb0eb3a5e6a977b7c1badca76337e9ce` |
| `https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.xz` | `fd8e59d5a511510f6a298afb548f18c7d2b1be404d8b4a27d94fbe49f56cb2d6` |

Both matched their official `SHASUMS256.txt`. The v22 manifest also listed
`node-v22.23.4-linux-arm64.tar.xz` with SHA256
`6287aa46b6c375d816e63ae66d024fbbfd70404825aabdfdf898a970871d2f4b`, and
`node-v22.23.4-darwin-arm64.tar.xz` with SHA256
`037650d0839f457747396f052073fb48333d31bf5abd3c98b74da20d89ebb1ad`.
Those two Node archives were not downloaded or executed.

## Nix cache and integration findings

For root Nixpkgs at the supplied pin, `nodejs_22` evaluates to 22.23.4 on each
requested platform. The following exact outputs had HTTP 200 narinfos on
`https://cache.nixos.org`:

| Platform | Node 22.23.4 output |
| --- | --- |
| x86_64-linux | `/nix/store/lr2c5f2y7q62pzfrkclgsy5yj31hsn5l-nodejs-22.23.4` |
| aarch64-linux | `/nix/store/bwkaqhf9650zqdk497yifczi89xxg573-nodejs-22.23.4` |
| aarch64-darwin | `/nix/store/dwm5sm9a4287fdim8cxyc5v6v8sq6iww-nodejs-22.23.4` |

The x64 Node 22 narinfo also returned HTTP 200 on Numtide; the two ARM Node 22
narinfos returned 404 there. NixOS coverage is sufficient for those outputs.
`nix copy --from https://cache.nixos.org` fetched the x64 runtime and its closure;
no source build was performed. The executed output reported Node 22.23.4 and
OpenSSL 3.5.9.

Root-pinned Node 24.21.0 had HTTP 200 narinfos on both caches for all three
platforms. Its exact outputs were:

- x64 Linux: `/nix/store/j1j9b0w3mhpccdli73ycj5w7nf6fkzqz-nodejs-24.21.0`.
- ARM Linux: `/nix/store/6vlx51wp6rjcsb1gcx54hfb7ndf3k2h8-nodejs-24.21.0`.
- Apple Silicon: `/nix/store/i376rizbw75rswsg2qlk47wj4zz3biqq-nodejs-24.21.0`.

Only the x64 Node 24 output was fetched and executed. Foreign-platform narinfo
availability is not an execution or full transitive-closure verification.

### Smallest maintainable candidate

The [pinned llm-agents recipe](https://github.com/numtide/llm-agents.nix/blob/53a2d94ce3b88753200be9a0549d8978b031fa60/packages/pi/package.nix)
already downloads built npm Pi, supplies a dependency lock, and offers
`useBun = false`. That branch omits `bun build --compile` and retains the Node
entry point. The explicit runtime override below evaluated successfully:

```nix
llmAgentsPkgs.pi.override {
  useBun = false;
  buildNpmPackage = pkgs.buildNpmPackage.override {
    nodejs = pkgs.nodejs_22;
  };
}
```

Here `pkgs` must be the supplied root Nixpkgs pin, not llm-agents' transitive
package set. The evaluated candidate output was
`/nix/store/r6iqz2mngbv5xyi1zfrac510h9k2fvdb-pi-1.4.0`, with derivation
`/nix/store/4ml20mrgvrvy47ikkaxmzia3n9508rcv-pi-1.4.0.drv`.
A dry-run with NixOS and Numtide substituters reported only the Pi assembly
derivation needing a build; dependencies were substitutes. **The candidate
itself was not built**, and this does not prove its installation hooks or final
closure. Avoiding Pi compilation is not the same as avoiding Nix assembly.

Without the explicit override, llm-agents' own package set selected a different
Node 24.21.0 output, `/nix/store/gxq2cd70i077rah1d4hkzc1lpq8q4pv8-nodejs-24.21.0`.
That is not the root-pinned Nix Node 24 output tested above, and its TLS behavior
was not tested.

### Linux native-library caveat

The npm package actually ships native TUI helpers for Linux x64, Linux ARM64,
and Darwin ARM64. However, loading its x64 `linux-platform-x11.node` with cached
Node failed with `libxcb.so.1` missing. Supplying
`LD_LIBRARY_PATH=/nix/store/d5dsf0h0r0fpi48rgvi7hmnac3mzj2s8-libxcb-1.17.0/lib`
made it load and expose `getText` and `getImage`; photon loaded successfully too.
The library was obtained from the NixOS cache.

The pinned llm-agents recipe's `useBun = false` branch does not provide the
Linux helper fixup needed by this probe. A complete integration needs targeted
native RPATH/autoPatchelf handling and `libxcb`, plus a native-module load check.
Upstream Pi's own Node Nix recipe provides an example of `autoPatchelfHook`,
`libxcb`, and direct native-module checks. The temporary `LD_LIBRARY_PATH` probe
is evidence of the dependency, not a recommended global environment setting.

Prefer that small extension of the existing recipe over duplicating a complete
Pi derivation. Keep the selected package shared by the agent baseline,
`toolnix-pi`, and Compound's subagent-example lookup. The existing Node-layout
candidate path is
`lib/node_modules/@earendil-works/pi-coding-agent/examples/extensions/subagent`;
see `modules/shared/compound-engineering.nix`. Preserve that example in the
assembled package rather than retaining only the CLI entry point.

## Settings, skills, and wrapped Pi compatibility

An isolated install used the v1.4.0 release install package and lock with
`npm ci --ignore-scripts --no-audit --no-fund`. It installed 120 packages, and
the bundled Node CLI returned `1.4.0` for `--version`.

The probe agent directory linked Toolnix's tracked settings, keybindings, and
all four extensions (`qna`, `ask-user`, `loop`, `login-url-padding`), plus the
managed Ponytail skill from the adjacent agent-skills checkout. RPC ran with
`--no-session --no-mcp`, with the shipped subagent example explicitly loaded.
Both the official standalone Pi and the npm CLI under cached Node 22 returned
successful `get_commands` responses listing `qna`, `loop`, and `skill:ponytail`,
with no extension-load diagnostics. This exercises mixed legacy
`@mariozechner` and current `@earendil-works` imports; it does not exercise every
registered tool or interactive handler.

The npm SDK's `SettingsManager` read the linked configuration as:

```json
{
  "provider": "openai-codex",
  "model": "gpt-6-astra",
  "thinking": "high",
  "compaction": {
    "enabled": true,
    "reserveTokens": 100000,
    "keepRecentTokens": 20000
  }
}
```

Without credentials, `get_state` reported an unknown active model and thinking
off, and `--list-models` reported no available models. Those observations do not
contradict successful settings parsing, nor establish authenticated model access.

The inspected Toolnix wrapper seeds missing managed files, preserves existing
valid files/symlinks, sets `PI_CODING_AGENT_DIR` and `PI_SKIP_VERSION_CHECK`, and
executes the selected package's `bin/pi`. The npm route fits that contract by
inspection and isolated simulation. The source thread's unpublished wrapper was
not built or executed. In particular, no real `auth.json` was linked into the
probe. Full skill inventory, keyboard bindings, login UI, model calls, and ARM
or macOS runtime behavior remain unverified.

## Provenance and reproducibility

- Standalone archives matched upstream `SHA256SUMS` and GitHub API digests.
  No signed binary attestation or byte-identical rebuild was established.
- The npm package URL is
  `https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-1.4.0.tgz`.
  Its registry integrity was
  `sha512-Z41LpZ3yYHSC/UUps6Mr39UMFPwH8elhJBG9DY1P7kuzsE5qSK/6eMj2EHzO5evJRQWLbKSqUMw+4nCNtIyiQg==`.
  `npm ci` checked the release lock's dependency integrity; plain floating npm
  installation is not equivalent to using that lock.
- Release `pi-coding-agent-install-package.json` SHA256:
  `9792b34aba5a94320fde5c68600eac4a5720d0d63ebc527d462bd125665b29ee`.
- Release `pi-coding-agent-install-package-lock.json` SHA256:
  `eb2c76ac270f099f2af3cbc6ccd08c3d22bf562b914af3690d1abba985461ade`.
- The registry exposes signatures and SLSA provenance. Decoded provenance names
  the v1.4.0 tag, `.github/workflows/build-binaries.yml`, the release commit, and
  Actions run 39686887346. Its signature chain was not independently verified.
- Official Node archive hashes matched official checksum manifests, but Node
  checksum-signing keys were not independently verified here.
- Nix cache copies used normal signature-checked substitution. Only x64
  runtimes were realized. A fixed Nix input, npm dependency lock, and exact
  runtime selection provide separately reviewable inputs; bit-reproducibility
  of the complete candidate Pi output was not tested.

Do not run a mutable installer or resolve `latest` during activation. Pin the
application, dependencies, and runtime separately, then test the resulting
package. Ask the owner before any large source build or retry; cache misses are
not permission to compile on the host.

## Evidence and follow-up boundary

- [Raw probe evidence](2026-10-25-pi-prebuilt-emudhra-tls/probes.json): complete
  runtime versions, the probe source, eight named TLS runs, and two RPC command
  responses. Each TLS run contains 32 observations plus a runtime-version row.
- [Release artifact manifest](2026-10-25-pi-prebuilt-emudhra-tls/release-artifacts.json):
  exact upstream asset URLs, hashes, sizes, release tag, and publication time.
- [Investigation thread](https://ampcode.com/threads/T-01a171e8-bd44-7414-bcf9-95bd2dfaf117).

The JSON evidence retains original disposable probe paths for traceability;
those installations were deleted. The embedded probe source can be reused with
a new extracted chain directory and isolated HOME.

This record does not authorize switching packages. The conservative immediate
choice remains the source thread's already-proven Bun 1.4.4 build. An alternative
follow-up would complete and verify Node 22 packaging across the three platforms,
including native helpers and Toolnix consumers. A future standalone release
should be re-downloaded, hash-checked, queried for its embedded Bun runtime, and
run through the same negative and healthy-control matrix before selection.
