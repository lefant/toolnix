# Coding-agent refresh and Astra defaults

## Goal

Update all coding agents supplied by Toolnix to the latest versions packaged by the shared `llm-agents` input. Make `gpt-6-astra` with high effort the default for Pi and Codex. Use Astra in OpenCode only if the updated package supports it; otherwise retain Sol, as requested.

## Research

- The shared agent baseline supplies Claude Code, Codex, Pi, OpenCode, Amp, and Beads from `llm-agents`.
- Both lockfiles currently pin `5dccb49e725e998cd006a13b423b3f58bcc2122e`.
- All three model templates already specify high effort. Pi 0.84.2 lists Astra through `openai-codex`; its auth check reports ready.
- OpenCode 1.18.18 does not list Astra, even with `--refresh` or `--pure`, although its downloaded models.dev catalog contains the model.
- Home Manager force-manages all three configuration files. Codex's template comments incorrectly describe container-era seed-only ownership.
- Wrapped Pi uses the same template but seeds missing or broken links only. Existing settings remain unchanged on wrapper rebuild.
- No focused model-default tests exist. Use parsed configuration assertions, actual CLI probes, and Nix builds instead of adding tests that merely duplicate these literal settings.

## Implementation

1. Refresh only `llm-agents` and its transitive inputs in both lockfiles. Keep unrelated top-level inputs unchanged.
2. Build the updated agent packages and check versions and model support.
3. Update supported primary model defaults, retaining high effort, OpenCode's small model, Pi's compaction settings, credentials, and permission settings. Correct Codex ownership comments.
4. Update the model reference and record results and limitations in a devlog.

## Verification

- Confirm both lockfiles resolve the same `llm-agents` revision and NAR hash.
- Parse JSON/TOML and assert primary model and high-effort defaults.
- Run `nix flake check --accept-flake-config` and build the Home Manager activation package and wrapped Pi.
- Run `devenv shell -- true`.
- Probe updated CLI versions; check Pi's Astra catalog/auth readiness and OpenCode's refreshed catalog.
- Verify generated Home Manager files match the tracked templates. Host activation is a separate rollout step.

## Boundaries

Do not migrate credentials, change permission policy, update skills or unrelated top-level Nix inputs, or add speculative custom model metadata to bypass unsupported clients. Existing sessions and project overrides can retain previous model selections.
