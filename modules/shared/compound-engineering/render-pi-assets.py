#!/usr/bin/env python3
"""Render Pi-compatible Compound Engineering assets from the upstream plugin."""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

DESCRIPTION_MAX_LENGTH = 1024


def normalize_name(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[\\/]+", "-", value)
    value = re.sub(r"[:\s]+", "-", value)
    value = re.sub(r"[^a-z0-9_-]+", "-", value)
    value = re.sub(r"-+", "-", value)
    value = value.strip("-")
    return value or "item"


def sanitize_description(value: str) -> str:
    normalized = re.sub(r"\s+", " ", value).strip()
    if len(normalized) <= DESCRIPTION_MAX_LENGTH:
        return normalized
    return normalized[: DESCRIPTION_MAX_LENGTH - 3].rstrip() + "..."


def transform_content_for_pi(body: str) -> str:
    result = body

    task_pattern = re.compile(r"^(\s*-?\s*)Task\s+([a-z][a-z0-9:-]*)\(([^)]*)\)", re.MULTILINE)

    def task_repl(match: re.Match[str]) -> str:
        prefix, agent_name, args = match.groups()
        final_segment = agent_name.split(":")[-1]
        skill_name = normalize_name(final_segment)
        trimmed_args = re.sub(r"\s+", " ", args.strip())
        if trimmed_args:
            return f'{prefix}Run subagent with agent="{skill_name}" and task="{trimmed_args}".'
        return f'{prefix}Run subagent with agent="{skill_name}".'

    result = task_pattern.sub(task_repl, result)
    result = re.sub(r"\bTask(?:Create|Update|List|Get|Stop|Output)\b", "the platform's task-tracking primitive", result)
    result = re.sub(r"\bTodoWrite\b", "the platform's task-tracking primitive", result)
    result = re.sub(r"\bTodoRead\b", "the platform's task-tracking primitive", result)

    slash_pattern = re.compile(r"(?<![:\w])/([a-z][a-z0-9_:-]*?)(?=[\s,.\"')\]}`]|$)", re.IGNORECASE)
    path_like = {"dev", "tmp", "etc", "usr", "var", "bin", "home"}

    def slash_repl(match: re.Match[str]) -> str:
        command_name = match.group(1)
        if "/" in command_name:
            return match.group(0)
        if command_name in path_like:
            return match.group(0)
        if command_name.startswith("skill:"):
            return "/skill:" + normalize_name(command_name[len("skill:") :])
        without_prefix = command_name[len("prompts:") :] if command_name.startswith("prompts:") else command_name
        return "/" + normalize_name(without_prefix)

    return slash_pattern.sub(slash_repl, result)


def parse_frontmatter(content: str) -> tuple[dict[str, str], str]:
    match = re.match(r"\A---\n(.*?)\n---\n?(.*)\Z", content, re.DOTALL)
    if not match:
        return {}, content

    frontmatter_text, body = match.groups()
    frontmatter: dict[str, str] = {}
    for line in frontmatter_text.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        value = value.strip().strip('"').strip("'")
        frontmatter[key.strip()] = value
    return frontmatter, body


def render_frontmatter(fields: dict[str, str], body: str) -> str:
    lines = ["---"]
    for key, value in fields.items():
        escaped = value.replace('"', '\\"')
        lines.append(f'{key}: "{escaped}"')
    lines.append("---")
    lines.append(body.strip())
    return "\n".join(lines).rstrip() + "\n"


def copy_skill_dir(source: Path, target: Path) -> None:
    for path in source.rglob("*"):
        rel = path.relative_to(source)
        dest = target / rel
        if path.is_dir():
            dest.mkdir(parents=True, exist_ok=True)
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        if path.name == "SKILL.md":
            dest.write_text(transform_content_for_pi(path.read_text()), encoding="utf-8")
        else:
            shutil.copy2(path, dest)


def render_agent(source: Path, target: Path) -> None:
    frontmatter, body = parse_frontmatter(source.read_text(encoding="utf-8"))
    name = normalize_name(frontmatter.get("name", source.stem.replace(".agent", "")))
    description = sanitize_description(frontmatter.get("description", f"Converted from Claude agent {name}"))
    content = render_frontmatter({"name": name, "description": description}, body)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: render-pi-assets.py PLUGIN_ROOT OUT", file=sys.stderr)
        return 2

    plugin_root = Path(sys.argv[1])
    out = Path(sys.argv[2])
    skills_out = out / "skills"
    agents_out = out / "agents"
    skills_out.mkdir(parents=True, exist_ok=True)
    agents_out.mkdir(parents=True, exist_ok=True)

    for skill in sorted((plugin_root / "skills").iterdir()):
        if skill.is_dir() and (skill / "SKILL.md").exists():
            copy_skill_dir(skill, skills_out / skill.name)

    for agent in sorted((plugin_root / "agents").glob("*.md")):
        name = normalize_name(agent.name.removesuffix(".agent.md").removesuffix(".md"))
        render_agent(agent, agents_out / f"{name}.md")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
