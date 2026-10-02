"""Check the Antithesis package without running its operational helpers."""

import json
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

source, plugin, exporter = map(Path, sys.argv[1:])
names = sorted("agent-browser debug documentation feature-workload launch mutation-testing query-logs research review-inputs setup setup-k8s skills-feedback triage workload".split())
manifest = json.loads((plugin / "antithesis.lock.json").read_text())
assert manifest["source"]["revision"] == "1fd8470d36a9629a75bda4619a5589d679a40d7c"
assert manifest["skills"] == [{"upstream": f"antithesis-{n}", "bundled": n} for n in names]
assert (plugin / "LICENSE").read_bytes() == (source / "LICENSE").read_bytes()
assert (plugin / "SOURCE.md").read_bytes() == (source / "SOURCE.md").read_bytes()
assert len([p for p in plugin.rglob("*") if p.is_file()]) == 111
for name in names:
    original = source / f"antithesis-{name}"
    target = plugin / "skills" / name
    assert sorted(p.relative_to(original) for p in original.rglob("*") if p.is_file()) == sorted(
        p.relative_to(target) for p in target.rglob("*") if p.is_file())
    for path in original.rglob("*"):
        if not path.is_file():
            continue
        rendered = target / path.relative_to(original)
        assert not rendered.is_symlink()
        assert (path.stat().st_mode & 0o111) == (rendered.stat().st_mode & 0o111)
        if path == original / "SKILL.md":
            upstream = path.read_text()
            result = rendered.read_text()
            frontmatter = re.match(r"\A---\n.*?\n---\n", upstream, re.S)[0]
            assert result.startswith(frontmatter.replace(f"name: antithesis-{name}\n", f"name: {name}\n"))
            assert result.endswith(upstream[len(frontmatter):])
            for n in names:
                assert f"`antithesis-{n}` → `antithesis:{n}`" in result
            assert "Modified by Toolnix" in result
            assert "does not authorize" in result
        else:
            assert path.read_bytes() == rendered.read_bytes(), path
    assert f"await amp.registerSkill({{ path: 'skills/{name}' }})" in (plugin / "index.ts").read_text()

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)

    def export(destination, ok=True, src=plugin):
        result = subprocess.run(["bash", str(exporter), "--source", str(src), str(destination)],
                                capture_output=True, text=True)
        assert (result.returncode == 0) == ok, result.stdout + result.stderr

    destination = root / "plugins"
    destination.mkdir()
    (destination / "mp.ts").write_text("unrelated plugin")
    export(destination)
    (destination / "antithesis/stale.txt").write_text("stale")
    export(destination)
    assert not (destination / "antithesis/stale.txt").exists()
    assert (destination / "mp.ts").read_text() == "unrelated plugin"
    for kind in ["directory", "single-file", "symlink", "wrong-owner"]:
        collision = root / kind
        collision.mkdir()
        if kind == "single-file":
            (collision / "antithesis.ts").write_text("preserve")
        elif kind == "symlink":
            (collision / "antithesis").symlink_to(destination / "antithesis")
        else:
            (collision / "antithesis").mkdir()
            if kind == "wrong-owner":
                (collision / "antithesis/antithesis.lock.json").write_text('{}')
        export(collision, ok=False)
        assert (destination / "antithesis/index.ts").exists()

    malformed = root / "malformed"
    shutil.copytree(plugin, malformed)
    for path in malformed.rglob("*"):
        path.chmod(path.stat().st_mode | stat.S_IWUSR)
    (malformed / "skills/triage/SKILL.md").unlink()
    before = (destination / "antithesis/index.ts").read_bytes()
    export(destination, ok=False, src=malformed)
    assert (destination / "antithesis/index.ts").read_bytes() == before

print("PASS: 14 skills, 111 files, resource/mode fidelity, namespace mapping, guarded export")
