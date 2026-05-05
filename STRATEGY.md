---
name: Toolnix
last_updated: 2026-05-04
---

# Toolnix Strategy

## Target problem

Agent-native coding needs disposable environments where implementation and verification can run freely. A laptop Docker workflow creates friction because an agent inside a container cannot safely rebuild the container from within the same trust boundary.

## Our approach

Toolnix uses dedicated, Toolnix-managed VMs and Nix-managed setup so implementation can run free inside the environment without mixing security boundaries. The bet is agent-native self-testing: prompt the agent to modify and verify locally or on a test VM directly, with fewer allow/deny interruptions.

## Who it's for

**Primary:** Fabian / lefant as the Toolnix maintainer - hiring Toolnix to have an opinionated setup quickly and easily available across many projects with many different approaches.

**Secondary:** Engineers running agent-native coding sessions on disposable VMs - hiring Toolnix to get a working baseline without hand-building each environment.

## Key metrics

- **Regression-free rollouts** - whether changes roll out to configured VMs without breaking expected working setups; measured by VM verification checks and rollout notes.
- **Manual post-bootstrap steps** - how many manual actions are needed after a fresh Toolnix bootstrap before agent-native coding works; measured by bootstrap/test VM runs.
- **Attention time for config changes** - how much human attention is needed to implement and verify new features or config changes; measured qualitatively from devlogs and session notes.

_This section is worth revisiting: the current metric set is directionally right but not yet fully instrumented._

## Tracks

### Devenv/project consumer baseline

Make project shells inherit the opinionated Toolnix setup through the published project interface.

_Why it serves the approach:_ disposable project environments should come up with the agent-ready defaults already present.

### Flake-parts/module interface

Keep the published Nix surface clean, composable, and usable from both host profiles and project consumers.

_Why it serves the approach:_ the setup must stay declarative and reusable instead of becoming per-machine glue.

### Agent-native verification docs

Encode plain-language verification instructions agents can run on VMs, including checks that may need to be ported from `lefant/hackbox-ctrl`.

_Why it serves the approach:_ the product works when agents can change Toolnix and verify the result in the target environment.

## Not working on

- Going full NixOS for every Toolnix-configured Linux machine, VM, or physical host.

## Marketing

**Tagline:** "We are going to be the last generation of developers to write code by hand, so let's have fun doing it." -- Dr. Erik Meijer
