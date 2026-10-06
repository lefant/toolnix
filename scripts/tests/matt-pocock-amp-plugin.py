"""Verify packaging fidelity and guarded export without executing workflows."""

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

source, plugin, exporter = map(Path, sys.argv[1:])
manifest = json.loads((plugin / "matt-pocock.lock.json").read_text())
names = sorted(p.name for p in source.iterdir() if p.is_dir())
assert len(names) == 27
assert [s["bundled"] for s in manifest["skills"]] == names
assert manifest["source"]["version"] == "1.3.1"
assert manifest["source"]["revision"] == "24fe0ef7737efae15c87225755e9f6f5965e4888"
assert "ask-matt/SKILL.md" in manifest["source"]["vendorDifference"]
assert {"implement-spec", "pr", "retro"} <= set(names)
assert "resolving-merge-conflicts" not in names
assert (plugin / "LICENSE").read_bytes() == (source / "LICENSE").read_bytes()
assert len(list(plugin.rglob("SKILL.md"))) == 27
assert len([p for p in plugin.rglob("*") if p.is_file()]) == 82  # Below Amp's 200-file limit.
manual_count = 0
for name in names:
    original = source / name
    target = plugin / "skills" / name
    assert sorted(p.relative_to(original) for p in original.rglob("*") if p.is_file()) == sorted(
        p.relative_to(target) for p in target.rglob("*") if p.is_file()
    )
    for path in original.rglob("*"):
        if not path.is_file():
            continue
        rendered = target / path.relative_to(original)
        if path.name != "SKILL.md":
            assert path.read_bytes() == rendered.read_bytes(), path
        else:
            upstream = path.read_text()
            result = rendered.read_text()
            frontmatter = re.match(r"\A---\n.*?\n---\n", upstream, re.S)[0]
            assert result.startswith(frontmatter)
            assert result.endswith(upstream[len(frontmatter):])
            assert "`prototype` → `mp:prototype`" in result
            assert "`code-review` → `mp:code-review`" in result
            assert "does not run setup or authorize" in result
            for invoked in re.findall(r'Call the Skill tool with [`"]([a-z-]+)[`"]', upstream, re.I):
                assert invoked in names, (name, invoked)
                assert f"`{invoked}` → `mp:{invoked}`" in result, (name, invoked)
            for link in re.findall(r'\]\((\./[^)#]+\.md)\)', upstream):
                assert (original / link).is_file(), (name, link)
            manual = "disable-model-invocation: true" in frontmatter
            manual_count += manual
            assert ("Upstream marks this skill manual-only" in result) == manual
        assert not rendered.is_symlink()
    assert f"await amp.registerSkill({{ path: 'skills/{name}' }})" in (plugin / "index.ts").read_text()
assert manual_count == 16

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)

    def export(destination, ok=True, src=plugin):
        result = subprocess.run(["bash", str(exporter), "--source", str(src), str(destination)],
                                capture_output=True, text=True)
        assert (result.returncode == 0) == ok, result.stdout + result.stderr

    destination = root / "plugins"
    destination.mkdir()
    (destination / "ce.ts").write_text("unrelated plugin")
    export(destination)
    (destination / "mp/stale.txt").write_text("stale")
    export(destination)
    assert not (destination / "mp/stale.txt").exists()
    assert (destination / "ce.ts").read_text() == "unrelated plugin"
    assert (destination / "mp/LICENSE").read_bytes() == (source / "LICENSE").read_bytes()

    for kind in ["directory", "single-file", "symlink", "wrong-owner"]:
        collision = root / kind
        collision.mkdir()
        if kind == "directory":
            (collision / "mp").mkdir()
        elif kind == "single-file":
            (collision / "mp.ts").write_text("do not replace")
        elif kind == "symlink":
            (collision / "mp").symlink_to(destination / "mp")
        else:
            (collision / "mp").mkdir()
            (collision / "mp/matt-pocock.lock.json").write_text('{}')
        export(collision, ok=False)
        assert (destination / "mp/index.ts").exists()

    malformed = root / "malformed"
    shutil.copytree(plugin, malformed)
    subprocess.run(["chmod", "-R", "u+rwX", str(malformed)], check=True)
    (malformed / "skills/tdd/SKILL.md").unlink()
    before = (destination / "mp/index.ts").read_bytes()
    export(destination, ok=False, src=malformed)
    assert (destination / "mp/index.ts").read_bytes() == before

print("PASS: 27 skills, 82 files, 16 manual flags, Skill-tool and local links, resource fidelity, export/update/collision safety")
