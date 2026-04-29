#!/usr/bin/env python3
"""Render OpenCode-compatible Compound Engineering assets from upstream."""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path


def parse_frontmatter(content: str) -> tuple[dict[str, object], str]:
    match = re.match(r"\A---\n(.*?)\n---\n?(.*)\Z", content, re.DOTALL)
    if not match:
        return {}, content

    frontmatter_text, body = match.groups()
    frontmatter: dict[str, object] = {}
    current_list: list[str] | None = None
    for line in frontmatter_text.splitlines():
        stripped = line.strip()
        if current_list is not None and stripped.startswith("-"):
            current_list.append(stripped[1:].strip().strip('"').strip("'"))
            continue
        current_list = None
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value.startswith("[") and value.endswith("]"):
            frontmatter[key] = [item.strip().strip('"').strip("'") for item in value[1:-1].split(",") if item.strip()]
        elif value == "":
            frontmatter[key] = []
            current_list = frontmatter[key]  # type: ignore[assignment]
        else:
            frontmatter[key] = value.strip('"').strip("'")
    return frontmatter, body


def skill_enabled_for_opencode(skill_dir: Path) -> bool:
    frontmatter, _ = parse_frontmatter((skill_dir / "SKILL.md").read_text(encoding="utf-8"))
    platforms = frontmatter.get("ce_platforms")
    return not isinstance(platforms, list) or "opencode" in platforms


def render_frontmatter(fields: dict[str, str], body: str) -> str:
    lines = ["---"]
    for key, value in fields.items():
        escaped = value.replace('"', '\\"')
        lines.append(f'{key}: "{escaped}"')
    lines.append("---")
    lines.append(body.strip())
    return "\n".join(lines).rstrip() + "\n"


def rewrite_claude_paths(body: str) -> str:
    return body.replace("~/.claude/", "~/.config/opencode/").replace(".claude/", ".opencode/")


def transform_skill_content_for_opencode(body: str) -> str:
    result = rewrite_claude_paths(body)
    # Rewrite fully qualified agent refs: plugin:category:agent-name -> agent-name.
    result = re.sub(
        r"(?<![a-z0-9:/-])[a-z][a-z0-9-]*:[a-z][a-z0-9-]*:([a-z][a-z0-9-]*)(?![a-z0-9:-])",
        r"\1",
        result,
        flags=re.IGNORECASE,
    )
    # Rewrite category-qualified Compound agent refs: category:ce-agent -> ce-agent.
    result = re.sub(
        r"(?<![a-z0-9:/-])[a-z][a-z0-9-]*:(ce-[a-z][a-z0-9-]*)(?![a-z0-9:-])",
        r"\1",
        result,
        flags=re.IGNORECASE,
    )
    return result


def copy_skill_dir(source: Path, target: Path) -> None:
    for path in source.rglob("*"):
        rel = path.relative_to(source)
        dest = target / rel
        if path.is_dir():
            dest.mkdir(parents=True, exist_ok=True)
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        if path.suffix == ".md":
            dest.write_text(transform_skill_content_for_opencode(path.read_text(encoding="utf-8")), encoding="utf-8")
        else:
            shutil.copy2(path, dest)


def render_agent(source: Path, target: Path) -> None:
    frontmatter, body = parse_frontmatter(source.read_text(encoding="utf-8"))
    name = str(frontmatter.get("name", source.name.removesuffix(".agent.md").removesuffix(".md")))
    description = str(frontmatter.get("description", f"Converted from Claude agent {name}"))
    fields = {
        "description": description,
        "mode": "subagent",
    }
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(render_frontmatter(fields, rewrite_claude_paths(body)), encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: render-opencode-assets.py PLUGIN_ROOT OUT", file=sys.stderr)
        return 2

    plugin_root = Path(sys.argv[1])
    out = Path(sys.argv[2])
    skills_out = out / "skills"
    agents_out = out / "agents"
    skills_out.mkdir(parents=True, exist_ok=True)
    agents_out.mkdir(parents=True, exist_ok=True)

    for skill in sorted((plugin_root / "skills").iterdir()):
        if skill.is_dir() and (skill / "SKILL.md").exists() and skill_enabled_for_opencode(skill):
            copy_skill_dir(skill, skills_out / skill.name)

    for agent in sorted((plugin_root / "agents").glob("*.md")):
        name = agent.name.removesuffix(".agent.md").removesuffix(".md")
        render_agent(agent, agents_out / f"{name}.md")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
