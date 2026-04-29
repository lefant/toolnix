#!/usr/bin/env python3
"""Render Codex-compatible Compound Engineering assets from upstream."""

from __future__ import annotations

import json
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


def parse_frontmatter(content: str) -> tuple[dict[str, object], str, str]:
    match = re.match(r"\A---\n(.*?)\n---\n?(.*)\Z", content, re.DOTALL)
    if not match:
        return {}, "", content

    frontmatter_text, body = match.groups()
    frontmatter: dict[str, object] = {}
    current_key: str | None = None
    current_list: list[str] | None = None
    for line in frontmatter_text.splitlines():
        stripped = line.strip()
        if current_list is not None and stripped.startswith("-"):
            current_list.append(stripped[1:].strip().strip('"').strip("'"))
            continue
        current_key = None
        current_list = None
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "|":
            frontmatter[key] = ""
            continue
        if value == "":
            frontmatter[key] = []
            current_key = key
            current_list = frontmatter[key]  # type: ignore[assignment]
            continue
        if value.startswith("[") and value.endswith("]"):
            items = [item.strip().strip('"').strip("'") for item in value[1:-1].split(",") if item.strip()]
            frontmatter[key] = items
        elif value.lower() == "true":
            frontmatter[key] = True
        elif value.lower() == "false":
            frontmatter[key] = False
        else:
            frontmatter[key] = value.strip('"').strip("'")
    return frontmatter, frontmatter_text, body


def skill_enabled_for_codex(skill_dir: Path) -> bool:
    frontmatter, _, _ = parse_frontmatter((skill_dir / "SKILL.md").read_text(encoding="utf-8"))
    platforms = frontmatter.get("ce_platforms")
    return not isinstance(platforms, list) or "codex" in platforms


def build_agent_targets(agent_names: list[str]) -> dict[str, str]:
    targets: dict[str, str] = {}
    for name in agent_names:
        target_name = normalize_name(name)
        aliases = {name, target_name}
        if target_name.startswith("ce-"):
            aliases.add(target_name[len("ce-") :])
        for alias in aliases:
            targets[normalize_name(alias)] = target_name
    return targets


def resolve_agent_target(value: str, agent_targets: dict[str, str]) -> str | None:
    parts = [part for part in value.split(":") if part]
    candidates = [normalize_name(value)]
    if len(parts) >= 2:
        candidates.append(normalize_name(":".join(parts[-2:])))
    if parts:
        candidates.append(normalize_name(parts[-1]))
    for candidate in candidates:
        target = agent_targets.get(candidate)
        if target:
            return target
    return None


def transform_content_for_codex(body: str, skill_names: set[str], agent_targets: dict[str, str]) -> str:
    result = body

    task_pattern = re.compile(r"^(\s*-?\s*)Task\s+([a-z][a-z0-9:-]*)\(([^)]*)\)", re.MULTILINE)

    def task_repl(match: re.Match[str]) -> str:
        prefix, agent_name, args = match.groups()
        agent_target = resolve_agent_target(agent_name, agent_targets)
        trimmed_args = args.strip()
        if agent_target:
            if trimmed_args:
                return f"{prefix}Spawn the custom agent `{agent_target}` with task: {trimmed_args}"
            return f"{prefix}Spawn the custom agent `{agent_target}`"
        final_segment = agent_name.split(":")[-1]
        skill_name = normalize_name(final_segment)
        if trimmed_args:
            return f"{prefix}Use the ${skill_name} skill to: {trimmed_args}"
        return f"{prefix}Use the ${skill_name} skill"

    result = task_pattern.sub(task_repl, result)

    backticked_agent_pattern = re.compile(r"`([a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*){1,2})`", re.IGNORECASE)
    result = backticked_agent_pattern.sub(
        lambda m: f"custom agent `{resolve_agent_target(m.group(1), agent_targets)}`" if resolve_agent_target(m.group(1), agent_targets) else m.group(0),
        result,
    )

    path_like = {"dev", "tmp", "etc", "usr", "var", "bin", "home"}
    slash_pattern = re.compile(r"(?<![:\w>}\]\)])/([a-z][a-z0-9_:-]*?)(?=[\s,.\"')\]}`]|$)", re.IGNORECASE)

    def slash_repl(match: re.Match[str]) -> str:
        command_name = match.group(1)
        if "/" in command_name or command_name in path_like:
            return match.group(0)
        normalized = normalize_name(command_name)
        if normalized in skill_names:
            return f"the {normalized} skill"
        return match.group(0)

    result = slash_pattern.sub(slash_repl, result)
    result = result.replace("~/.claude/", "~/.codex/").replace(".claude/", ".codex/")

    agent_ref_pattern = re.compile(r"@([a-z][a-z0-9-]*-(?:agent|reviewer|researcher|analyst|specialist|oracle|sentinel|guardian|strategist))", re.IGNORECASE)
    result = agent_ref_pattern.sub(
        lambda m: f"custom agent `{resolve_agent_target(m.group(1), agent_targets)}`" if resolve_agent_target(m.group(1), agent_targets) else f"${normalize_name(m.group(1))} skill",
        result,
    )
    return result


def copy_skill_dir(source: Path, target: Path, skill_names: set[str], agent_targets: dict[str, str]) -> None:
    for path in source.rglob("*"):
        rel = path.relative_to(source)
        dest = target / rel
        if path.is_dir():
            dest.mkdir(parents=True, exist_ok=True)
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        if path.name == "SKILL.md":
            dest.write_text(transform_content_for_codex(path.read_text(encoding="utf-8"), skill_names, agent_targets), encoding="utf-8")
        else:
            shutil.copy2(path, dest)


def render_agent(source: Path, target: Path) -> None:
    frontmatter, _, body = parse_frontmatter(source.read_text(encoding="utf-8"))
    name = normalize_name(str(frontmatter.get("name", source.name.removesuffix(".agent.md").removesuffix(".md"))))
    description = sanitize_description(str(frontmatter.get("description", f"Converted from Claude agent {name}")))
    instructions = body.strip() or f"Instructions converted from the {name} agent."
    target.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        f"name = {json.dumps(name)}",
        f"description = {json.dumps(description)}",
        f"developer_instructions = {json.dumps(instructions)}",
    ]
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: render-codex-assets.py PLUGIN_ROOT OUT", file=sys.stderr)
        return 2

    plugin_root = Path(sys.argv[1])
    out = Path(sys.argv[2])
    skills_out = out / "skills" / "compound-engineering"
    agents_out = out / "agents" / "compound-engineering"
    skills_out.mkdir(parents=True, exist_ok=True)
    agents_out.mkdir(parents=True, exist_ok=True)

    agent_files = sorted((plugin_root / "agents").glob("*.md"))
    agent_names = []
    for agent in agent_files:
        frontmatter, _, _ = parse_frontmatter(agent.read_text(encoding="utf-8"))
        agent_names.append(str(frontmatter.get("name", agent.name.removesuffix(".agent.md").removesuffix(".md"))))
    agent_targets = build_agent_targets(agent_names)

    skill_dirs = [skill for skill in sorted((plugin_root / "skills").iterdir()) if skill.is_dir() and (skill / "SKILL.md").exists() and skill_enabled_for_codex(skill)]
    skill_names = {normalize_name(skill.name) for skill in skill_dirs}

    for skill in skill_dirs:
        copy_skill_dir(skill, skills_out / normalize_name(skill.name), skill_names, agent_targets)

    for agent in agent_files:
        frontmatter, _, _ = parse_frontmatter(agent.read_text(encoding="utf-8"))
        name = normalize_name(str(frontmatter.get("name", agent.name.removesuffix(".agent.md").removesuffix(".md"))))
        render_agent(agent, agents_out / f"{name}.toml")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
