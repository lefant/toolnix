#!/usr/bin/env python3
"""Package the reviewed Antithesis snapshot as an Amp directory plugin."""

import json
import re
import shutil
import stat
import sys
from pathlib import Path

SKILLS = sorted("""agent-browser debug documentation feature-workload launch
mutation-testing query-logs research review-inputs setup setup-k8s
skills-feedback triage workload""".split())
UPSTREAM_REVISION = "1fd8470d36a9629a75bda4619a5589d679a40d7c"


def render(source: Path, out: Path, revision: str) -> None:
    if revision != "unlocked" and not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("expected the pinned agent-skills revision or unlocked path override")
    vendor = source / "vendor/antithesishq"
    if sorted(p.name for p in vendor.iterdir() if p.is_dir()) != sorted(
        f"antithesis-{name}" for name in SKILLS
    ):
        raise ValueError("review the published skill set before changing this snapshot")
    if UPSTREAM_REVISION not in (vendor / "SOURCE.md").read_text():
        raise ValueError("review the upstream revision before changing this snapshot")

    names = ", ".join(f"`antithesis-{name}` → `antithesis:{name}`" for name in SKILLS)
    guidance = f"""<!-- toolnix-amp-antithesis:start -->
## Amp Antithesis integration

Modified by Toolnix: shortened the frontmatter name and added this Amp guidance.
For skill invocation, discovery, and recommendations in this package and its
resources, resolve upstream skill names (including slash commands) as: {names}.
Preserve upstream names in feedback metadata, URLs, filenames, CLI commands,
environment variables, and generated project artifacts.

Resolve bundled `assets/` and `references/` paths relative to this installed
skill directory, including when a shell command needs an absolute path.
For resources attributed to another Antithesis skill, load that mapped skill
and resolve against its directory instead.
The project's `antithesis/` directory is an output location, not a bundled asset.
The generic `agent-browser` CLI/skill remains distinct from
`antithesis:agent-browser`, the tenant authentication helper. Follow its explicit
user-or-skill request gate and let the human complete interactive authentication.

Loading this plugin does not authorize installing dependencies, uploading images
or logs, submitting paid runs, changing clusters, or deleting user data. Obtain
approval for those actions and review bundled shell helpers before execution.
Mutation forks include gitignored files: explicitly exclude secrets before
copying or building. Validate the exact trusted HTTPS tenant origin before
injecting browser helpers; upstream URL-path checks do not validate origins.
Debugger `authorizeAll` is not human approval. Inspect commands before allowing
remote execution. Use the host's normal browser sandbox and human-visible login.
Keep credentials, saved browser authentication, downloaded logs, and debug output
out of Git and public reports. Use the host's available tools for subagent and
browser operations; report missing capabilities rather than claiming execution.
<!-- toolnix-amp-antithesis:end -->
"""
    (out / "skills").mkdir(parents=True)
    for name in SKILLS:
        target = out / "skills" / name
        shutil.copytree(vendor / f"antithesis-{name}", target)
        path = target / "SKILL.md"
        content = path.read_text()
        match = re.match(r"\A---\n(.*?)\n---(?:\n|\Z)", content, re.S)
        if not match or not re.search(rf"^name: antithesis-{re.escape(name)}$", match[1], re.M):
            raise ValueError(f"invalid skill frontmatter: {name}")
        frontmatter = content[:match.end()].replace(f"name: antithesis-{name}\n", f"name: {name}\n")
        path.chmod(path.stat().st_mode | stat.S_IWUSR)
        path.write_text(frontmatter + "\n" + guidance + "\n" + content[match.end():])

    registrations = "\n".join(
        f"\tawait amp.registerSkill({{ path: 'skills/{name}' }})" for name in SKILLS
    )
    (out / "index.ts").write_text(
        "import type { PluginAPI } from '@ampcode/plugin'\n\n"
        "export const description = 'Antithesis testing workflows bundled as Amp skills under the antithesis namespace.'\n\n"
        "export default async function (amp: PluginAPI) {\n" + registrations + "\n}\n"
    )
    shutil.copy2(vendor / "LICENSE", out / "LICENSE")
    shutil.copy2(vendor / "SOURCE.md", out / "SOURCE.md")
    (out / "antithesis.lock.json").write_text(json.dumps({
        "schemaVersion": 1,
        "source": {"repository": "https://github.com/antithesishq/antithesis-skills",
                   "revision": UPSTREAM_REVISION},
        "vendor": {"repository": "https://github.com/lefant/agent-skills", "revision": revision},
        "renderer": "toolnix", "pluginName": "antithesis",
        "skills": [{"upstream": f"antithesis-{name}", "bundled": name} for name in SKILLS],
    }, indent=2) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: render-amp-plugin.py AGENT_SKILLS_ROOT OUT AGENT_SKILLS_REVISION")
    render(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3])
