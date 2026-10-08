#!/usr/bin/env python3
"""Compare captured Home Manager packages/env/files without activation.

Capture each input with:
  nix eval --json .#homeConfigurations.lefant-toolnix.config --apply \
    'c: { env=c.home.sessionVariables; packages=map (p: p.outPath) c.home.packages;
    files=builtins.mapAttrs (_: f: {inherit (f) source target force;
    content=if builtins.pathExists "${f.source}/." then null
    else builtins.readFile f.source;}) c.home.file; }'
Capture contents through Nix: virtual source paths may not exist on disk.
"""
import json
from pathlib import Path
import re
import sys


def normalize(value):
    if isinstance(value, str):
        value = re.sub(r"/nix/store/[a-z0-9]+-source/", "<repo>/", value)
        return re.sub(r"/nix/store/[a-z0-9]+-toolnix-claude-statusline$", "<statusline>", value)
    if isinstance(value, list):
        return sorted(normalize(item) for item in value)
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def load(path):
    data = json.loads(Path(path).read_text())
    for entry in data["files"].values():
        if "content" not in entry:
            raise ValueError("Capture file contents with the documented Nix expression")
    return normalize(data)


if __name__ == "__main__":
    before, after = map(load, sys.argv[1:])
    differences = [key for key in before.keys() | after.keys() if before.get(key) != after.get(key)]
    if differences:
        raise SystemExit("FAIL Linux profile differs: " + ", ".join(sorted(differences)))
    print("PASS Linux packages, environment, managed file contents/targets/force")
