# HITL Browser Automation Runtime

Toolnix can provision the runtime dependencies for the portable `hitl-browser-automation` skill from `agent-skills`.

## Enablement

Home Manager host profile:

```nix
{
  toolnix.hitlBrowserAutomation.enable = true;
}
```

Project `devenv` consumer:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.toolnix}/modules/devenv/project.nix" ];
  toolnix.hitlBrowserAutomation.enable = true;
}
```

## What the option provides

- `hitl-browser-hub` command, wrapping the skill-owned script from `agent-skills`
- Nix-managed `agent-browser` behavior
- Toolnix Chromium environment variables
- Node.js, Python, `jq`
- Linux VNC/display tools for the Browser Debug Hub runtime

The skill remains the workflow and script source of truth. Toolnix only makes the runtime easy to satisfy.

## Home Manager vs devenv

Home Manager owns persistent agent skill installation under supported agent skill directories. `devenv` owns shell-local packages and environment variables only. A project shell can provide `hitl-browser-hub` and dependencies, but agent skill discovery still depends on host agent config or direct skill-path use.

## First run

From the target project/context directory:

```bash
hitl-browser-hub check
hitl-browser-hub start
hitl-browser-hub status
hitl-browser-hub stop
```

Remote VM use requires explicit local forwarding. Use the forwarding instructions printed by `hitl-browser-hub start`, then connect your VNC client to the forwarded loopback endpoint.

## State and privacy

Runtime state defaults outside the skill package and outside the project tree:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/hitl-browser-automation/<project-name>-<hash>/
```

Treat browser profiles, traces, screenshots, cookies, logs, and CDP artifacts as sensitive. Do not commit raw artifacts or paste them into chat unless explicitly reviewed and redacted.

## Validation shape

Cheap Toolnix checks prove option/package/env behavior. Full runtime smoke proofs require a browser/VNC-capable environment and enough disk space for Chromium/runtime state.

Use blocked/not-applicable language for hosts that lack VNC, browser runtime, or disk capacity rather than treating those local capacity constraints as Toolnix module failures.
