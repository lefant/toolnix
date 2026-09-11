#!/usr/bin/env python3
"""Render Compound Engineering as an Amp directory plugin named ``ce``."""

from __future__ import annotations

import json
import re
import shutil
import stat
import sys
from pathlib import Path

PLUGIN_NAME = "ce"
SOURCE_REPOSITORY = "https://github.com/EveryInc/compound-engineering-plugin"
NAMESPACE_RULE = """<!-- toolnix-amp-ce-namespace:start -->
## Amp `ce` plugin namespace

This package is registered as {qualified_name}. When these instructions or bundled references tell you to invoke, load, use, route to, hand off to, or recommend another Compound Engineering skill named `ce-<name>`, invoke the Amp bundled skill `ce:<name>` instead. Treat `lfg` the same way as `ce:lfg`.

This mapping applies only to skill selection and user-facing Amp skill names. Do not change upstream artifact metadata, configuration values, paths, environment variables, script arguments, run IDs, or filenames that use the original names.
<!-- toolnix-amp-ce-namespace:end -->
"""


def bundled_name(upstream_name: str) -> str:
    if upstream_name.startswith("ce-"):
        return upstream_name.removeprefix("ce-")
    return upstream_name


def qualify_skill_references(value: str, mappings: list[dict[str, str]]) -> str:
    result = value
    for mapping in sorted(mappings, key=lambda item: len(item["upstream"]), reverse=True):
        upstream = re.escape(mapping["upstream"])
        result = re.sub(
            rf"(?<![a-z0-9:-]){upstream}(?![a-z0-9-])",
            f'{PLUGIN_NAME}:{mapping["bundled"]}',
            result,
        )
    return result


def render_skill_file(
    path: Path,
    upstream_name: str,
    local_name: str,
    mappings: list[dict[str, str]],
) -> None:
    content = path.read_text(encoding="utf-8")
    frontmatter = re.match(r"\A---\n(.*?)\n---(?:\n|\Z)", content, re.DOTALL)
    if frontmatter is None:
        raise ValueError(f"missing YAML frontmatter: {path}")

    name_pattern = re.compile(r"^(name:\s*)['\"]?([^'\"\s]+)['\"]?\s*$", re.MULTILINE)
    name_match = name_pattern.search(frontmatter.group(1))
    if name_match is None:
        raise ValueError(f"missing frontmatter name: {path}")
    if name_match.group(2) != upstream_name:
        raise ValueError(
            f"skill directory/frontmatter mismatch: {upstream_name} != {name_match.group(2)}"
        )

    updated_frontmatter = name_pattern.sub(
        lambda match: f'{match.group(1)}"{local_name}"',
        frontmatter.group(1),
        count=1,
    )
    updated_frontmatter = re.sub(
        r"^(description:\s*)(.*)$",
        lambda match: match.group(1) + qualify_skill_references(match.group(2), mappings),
        updated_frontmatter,
        count=1,
        flags=re.MULTILINE,
    )
    body = content[frontmatter.end() :].lstrip("\n")
    namespace_rule = NAMESPACE_RULE.format(qualified_name=f"`{PLUGIN_NAME}:{local_name}`")
    path.chmod(path.stat().st_mode | stat.S_IWUSR)
    path.write_text(
        f"---\n{updated_frontmatter}\n---\n\n{namespace_rule}\n{body}",
        encoding="utf-8",
    )


def write_entrypoint(path: Path, names: list[str]) -> None:
    registrations = "\n".join(f'\t"{name}",' for name in names)
    path.write_text(
        "import type { PluginAPI } from '@ampcode/plugin'\n\n"
        "export const description =\n"
        "\t'Compound Engineering workflows bundled as Amp skills under the ce namespace.'\n\n"
        f"const skills = [\n{registrations}\n] as const\n\n"
        "export default async function (amp: PluginAPI) {\n"
        "\tfor (const skill of skills) {\n"
        "\t\tawait amp.registerSkill({ path: `skills/${skill}` })\n"
        "\t}\n"
        "}\n",
        encoding="utf-8",
    )


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: render-amp-plugin.py AMP_SKILLS_ROOT OUT", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    out = Path(sys.argv[2])
    revision = (source / "UPSTREAM_REVISION").read_text(encoding="utf-8").strip()
    if re.fullmatch(r"[0-9a-f]{40}", revision) is None:
        raise ValueError(f"invalid upstream revision: {revision}")

    skill_sources = sorted(
        path for path in source.iterdir() if path.is_dir() and (path / "SKILL.md").is_file()
    )
    if not skill_sources:
        raise ValueError(f"no skills found under {source}")

    mappings = [
        {"upstream": skill_source.name, "bundled": bundled_name(skill_source.name)}
        for skill_source in skill_sources
    ]
    local_names = [mapping["bundled"] for mapping in mappings]
    if len(local_names) != len(set(local_names)):
        raise ValueError("shortened bundled skill names are not unique")
    if any(re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) is None for name in local_names):
        raise ValueError("a shortened bundled skill name is invalid")

    skills_out = out / "skills"
    skills_out.mkdir(parents=True)
    for skill_source, mapping in zip(skill_sources, mappings, strict=True):
        local_name = mapping["bundled"]
        target = skills_out / local_name
        shutil.copytree(skill_source, target, symlinks=False)
        render_skill_file(target / "SKILL.md", skill_source.name, local_name, mappings)

    write_entrypoint(out / "index.ts", local_names)
    shutil.copy2(source / "UPSTREAM_LICENSE", out / "LICENSE")
    (out / "compound-engineering.lock.json").write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "source": {"repository": SOURCE_REPOSITORY, "revision": revision},
                "renderer": "toolnix",
                "pluginName": PLUGIN_NAME,
                "skills": mappings,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
