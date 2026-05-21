# Agent inputs bump

Updated the locked `llm-agents` input to the latest upstream `github:numtide/llm-agents.nix` revision and updated `agent-skills` to the revision that vendors the marimo skills. Kept `flake.lock` and `devenv.lock` aligned.

## Changes

- Updated `llm-agents` from `646ae209744976acee0c2c0eda0de7a68abbf015` to `339239b8e071b0294cc5b49b555d724761a68bf0` in both lockfiles.
- Updated `agent-skills` to `0ead8e51f6e3e704ab04d7e9a69d1fe56a3ff4e9`, which vendors `marimo-notebook` and `marimo-pair` skills.
- Accepted upstream transitive input updates for:
  - `llm-agents/bun2nix`
  - `llm-agents/flake-parts`
  - `llm-agents/nixpkgs`
- Preserved existing Toolnix module wiring; this was a lock-only refresh.

## Resolved package versions

- `claude-code`: `2.1.146`
- `codex`: `0.132.0`
- `pi`: `0.75.3`
- `opencode`: `1.15.6`
- `agent-browser`: `0.27.0`

## Verification

```bash
nix flake update llm-agents
devenv update llm-agents
nix flake lock --override-input agent-skills github:lefant/agent-skills/0ead8e51f6e3e704ab04d7e9a69d1fe56a3ff4e9
devenv update agent-skills
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux."claude-code".version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.codex.version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.pi.version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.opencode.version'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.llm-agents.packages.x86_64-linux.agent-browser.version'
nix flake check --no-build
```

`nix flake check --no-build` passed. Nix printed expected untrusted-user warnings for restricted cache settings in this exe.dev environment.
