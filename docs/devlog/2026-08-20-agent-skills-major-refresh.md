# Agent skills major refresh

Updated Toolnix's pinned `agent-skills` input from revision `42271a01c2fdf08f301726c6f821ae78c33eae83` to `f2e3970ee4234096ea8cdadf4016cd01a4be3740`. Kept `flake.lock` and `devenv.lock` aligned.

## Upstream changes

The refresh includes 33 upstream commits. Notable changes include:

- modular Remotion guidance under the existing `remotion-best-practices` skill;
- updated live-kernel workflows for `marimo-pair`;
- current package-matched documentation behavior for `ai-sdk`;
- updated `get-api-docs`, `frontend-design`, browser, Pulumi, Caveman, and transcript workflows;
- a locally owned Mermaid validation tool under `mermaid-diagrams`;
- removal of the redundant `mermaid` and `tavily-search` skills.

## Verification

Verified the repository and activation path with:

```bash
nix flake check --no-build
devenv shell -- true
nix build --out-link result-agent-skills-f2e3970 \
  .#homeConfigurations.lefant-toolnix.activationPackage
./result-agent-skills-f2e3970/activate
```

Confirmed after activation:

- both lockfiles contain the same revision and NAR hash;
- the managed Pi skill tree contains 104 skills;
- `mermaid-diagrams`, its executable `tools/validate.sh`, the modular Remotion references, and the updated `marimo-pair` references are present;
- retired `mermaid` and `tavily-search` skill paths are absent.

Started a fresh Pi session with `PI_OFFLINE=1 pi --verbose` in tmux session `pi-agent-skills-f2e3970`. Its startup discovery listed the refreshed `mermaid-diagrams`, `remotion-best-practices`, `marimo-pair`, and `get-api-docs` skills and did not list the retired `mermaid` or `tavily-search` skills.
