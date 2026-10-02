#!/usr/bin/env python3
"""Package the reviewed Matt Pocock snapshot as Amp's mp directory plugin."""

import json
import re
import shutil
import stat
import sys
from pathlib import Path

SKILLS = sorted("""ask-matt code-review codebase-design diagnosing-bugs domain-modeling
grill-me grill-with-docs grilling handoff implement implement-spec
improve-codebase-architecture pr prototype research retro setup-matt-pocock-skills
tdd teach to-questionnaire to-spec to-tickets triage wait-what wayfinder wizard
writing-for-agents""".split())
UPSTREAM_REVISION = "d81f3a183412e71a5b1e84ca21bc1a35eea03a60"


def render(source: Path, out: Path, revision: str) -> None:
    if revision != "unlocked" and not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("expected the pinned agent-skills revision or unlocked path override")
    vendor = source / "vendor/mattpocock"
    actual = sorted(p.name for p in vendor.iterdir() if p.is_dir())
    if actual != SKILLS:
        raise ValueError("review the published skill set before changing this snapshot")
    provenance = (source / "vendor/README.md").read_text()
    if UPSTREAM_REVISION not in provenance:
        raise ValueError("review the upstream revision before changing this snapshot")

    names = ", ".join(f"`{name}` → `mp:{name}`" for name in SKILLS)
    rule = f"""<!-- toolnix-amp-mp:start -->
## Amp MP integration

For skill selection, every Matt Pocock skill reference in this package and its
bundled resources resolves within `mp`, including slash commands, bare names,
and Skill tool arguments: {names}.
This applies only to skill invocation, discovery, and recommendations. Preserve
paths, URLs, ticket types, labels, artifact metadata, and script arguments.
Other harness commands such as `/clear` and `/compact` are not MP skills; use
Amp's available context controls instead of assuming those commands exist.

Select MP or CE explicitly for this task. Namespaces do not isolate instructions;
use fresh threads to compare families. Follow the project's existing document
ownership and approval rules. Loading this plugin does not run setup or authorize
project rewrites, tracker writes, credential operations, commits, or publication.
Run `mp:setup-matt-pocock-skills` only when the user requests project setup, and
review its proposed changes before applying them.

Review generated Bash before use: the diagnosing-bugs capture template echoes
observations, so never capture secrets. The wizard template can write `.env` and
GitHub Actions secrets/variables; keep secrets out of logs and Git, and obtain
authorization for remote writes. Architecture HTML reports load Tailwind and
Mermaid from third-party CDNs; review network/privacy requirements before opening
reports, or use approved local assets. Installation executes none of these.
<!-- toolnix-amp-mp:end -->
"""
    (out / "skills").mkdir(parents=True)
    for name in SKILLS:
        target = out / "skills" / name
        shutil.copytree(vendor / name, target)
        path = target / "SKILL.md"
        content = path.read_text()
        match = re.match(r"\A---\n(.*?)\n---(?:\n|\Z)", content, re.S)
        if not match or not re.search(rf"^name: {re.escape(name)}$", match[1], re.M):
            raise ValueError(f"invalid skill frontmatter: {name}")
        manual = "disable-model-invocation: true" in match[1].splitlines()
        guidance = rule
        if manual:
            guidance += "\nUpstream marks this skill manual-only. Require an explicit user request for\nthis skill; a matching description or another skill's recommendation is not enough.\n"
        path.chmod(path.stat().st_mode | stat.S_IWUSR)
        # Preserve all frontmatter (including manual flags) and upstream bytes.
        # A scoped mapping avoids rewriting generic words such as research or pr.
        path.write_text(content[:match.end()] + "\n" + guidance + "\n" + content[match.end():])

    registrations = "\n".join(
        f"\tawait amp.registerSkill({{ path: 'skills/{name}' }})" for name in SKILLS
    )
    (out / "index.ts").write_text(
        "import type { PluginAPI } from '@ampcode/plugin'\n\n"
        "export const description = 'Matt Pocock workflows bundled as Amp skills under the mp namespace.'\n\n"
        "export default async function (amp: PluginAPI) {\n"
        + registrations + "\n}\n"
    )
    shutil.copy2(vendor / "LICENSE", out / "LICENSE")
    (out / "matt-pocock.lock.json").write_text(json.dumps({
        "schemaVersion": 1,
        "source": {"repository": "https://github.com/mattpocock/skills",
                   "revision": UPSTREAM_REVISION, "version": "1.2.3"},
        "vendor": {"repository": "https://github.com/lefant/agent-skills", "revision": revision},
        "renderer": "toolnix", "pluginName": "mp",
        "skills": [{"upstream": name, "bundled": name} for name in SKILLS],
    }, indent=2) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: render-amp-plugin.py AGENT_SKILLS_ROOT OUT AGENT_SKILLS_REVISION")
    render(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3])
