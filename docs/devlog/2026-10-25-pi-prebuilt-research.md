---
date: 2026-10-25
status: ✅ COMPLETED
related_research: docs/research/2026-10-25-pi-prebuilt-emudhra-tls.md
---

# Record Pi prebuilt TLS research

Completed a read-only investigation into replacing Pi compilation with upstream
prebuilt distributions. Recorded exact artifacts and hashes, embedded runtimes,
release channels, platform/cache coverage, provenance limits, all TLS outcomes,
and settings/skills/wrapper compatibility in the linked research record.

## Findings

- Official Pi 1.4.0 standalone archives embed Bun 1.3.14. Executed x64 probes
  accepted seven incident endpoints, including No-CT; ARM artifacts were only
  inspected. Upstream's Bun 1.4.4 workflow change had not produced a newer public
  release at investigation time.
- npm Pi 1.4.0 under official or cached root-pinned Node 22.23.4 rejected all 14
  endpoints with `CERT_REVOKED`, through both `fetch` and `https`. Both healthy
  controls returned HTTP 200. The exact cached Nix Node 24 build also rejected
  all 14, but with issuer-chain errors, unlike official Node 24 with the same
  application version.
- The existing `useBun = false` recipe can avoid Pi compilation with an explicit
  fixed Node selection. Its evaluated candidate still needs Linux native-library
  fixup and final package verification. No Pi build or selection change was made.
- Isolated RPC and settings probes exercised the managed extensions, one
  representative skill, and the exact tracked preferences without credentials.
  Native helper loading succeeded after supplying cached `libxcb`.

## Documentation and compounding

Preserved eight TLS runs, complete runtime versions, the probe source, two RPC
responses, and the upstream release manifest beside the research document. The
disposable installations were deleted; historical temporary paths remain in the
JSON evidence for traceability.

Captured one reusable learning in
[Verify the Exact Prebuilt Runtime Before Selecting a TLS Fix](../solutions/tooling-decisions/pi-prebuilt-runtime-tls-verification.md).
Lightweight compounding was used for this long session; independent semantic
review and session-history synthesis were not run. Existing agent guidance
already surfaces `docs/solutions/`. `CONCEPTS.md` is absent; no vocabulary file
was bootstrapped by the lightweight pass.

## Verification and delivery boundary

Documentation checks cover frontmatter safety, local links, whitespace, and the
recorded JSON matrix against the written counts. The research retains the
distinction between executed x64 probes, foreign-architecture inspection/cache
availability, and source-thread observations from an unpublished security branch.

No package pins, package-selection modules, host state, credentials, or provider
configuration changed. The documentation publication does not authorize a
package rollout or a large source build.
