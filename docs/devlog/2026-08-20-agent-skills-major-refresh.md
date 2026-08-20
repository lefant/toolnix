# Agent skills major refresh

Updated Toolnix's pinned `agent-skills` input from revision `42271a01c2fdf08f301726c6f821ae78c33eae83` to `ea0b15ed7d2e86c5f4a9243ccf70a0a30b584757`. Kept `flake.lock` and `devenv.lock` aligned.

## Upstream changes

The refresh includes 38 upstream commits. Notable changes include:

- modular Remotion guidance under the existing `remotion-best-practices` skill;
- updated live-kernel workflows for `marimo-pair`;
- current package-matched documentation behavior for `ai-sdk`;
- updated `get-api-docs`, `frontend-design`, browser, Pulumi, Caveman, transcript, and TaskNotes workflows;
- a locally owned Mermaid validation tool under `mermaid-diagrams`;
- stronger upstream skill-metadata validation and empty-YAML test coverage;
- removal of the redundant `mermaid` and `tavily-search` skills and the vendored TaskNotes copy.

## Verification

Verified the repository and activation path with:

```bash
nix flake check --no-build
devenv shell -- true
nix build --out-link result-agent-skills-ea0b15e \
  .#homeConfigurations.lefant-toolnix.activationPackage
./result-agent-skills-ea0b15e/activate
```

Confirmed after activation:

- both lockfiles contain the same revision and NAR hash;
- the managed Pi skill tree contains 104 skills;
- `mermaid-diagrams`, its executable `tools/validate.sh`, the modular Remotion references, and the updated `marimo-pair` references are present;
- retired `mermaid` and `tavily-search` skill paths are absent.

Started a fresh Pi session with `PI_OFFLINE=1 pi --verbose` in tmux session `pi-agent-skills-ea0b15e`. Its startup discovery listed the refreshed `mermaid-diagrams`, `remotion-best-practices`, `marimo-pair`, `get-api-docs`, and `tasknotes` skills and did not list the retired `mermaid` or `tavily-search` skills.
