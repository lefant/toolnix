#!/usr/bin/env bash
set -euo pipefail

readonly SOURCE_REPOSITORY="https://github.com/EveryInc/compound-engineering-plugin"
readonly PLUGIN_NAME="ce"
readonly MANIFEST_NAME="compound-engineering.lock.json"

usage() {
  cat <<'EOF'
Usage:
  scripts/export-compound-engineering-amp-plugin.sh [--source <path>] <global-plugins-checkout>

Export Toolnix's pinned Compound Engineering collection as the `ce` directory
plugin in an existing Amp Global User or Workspace Plugins repository checkout.

The command replaces only a `ce` plugin carrying Toolnix's ownership manifest.
It does not clone the destination, run Git commands, commit, or push.

Options:
  --source <path>  Use an already built directory plugin instead of building the
                   compound-engineering-amp-plugin flake package.
  --help           Show this help.
EOF
}

source_path=""
destination=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source)
      if [ "$#" -lt 2 ]; then
        echo "ERROR: --source requires a path" >&2
        exit 2
      fi
      source_path="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -n "$destination" ]; then
        echo "ERROR: expected one destination path" >&2
        usage >&2
        exit 2
      fi
      destination="$1"
      shift
      ;;
  esac
done

if [ -z "$destination" ]; then
  echo "ERROR: a Global Plugins repository checkout is required" >&2
  usage >&2
  exit 2
fi
if [ ! -d "$destination" ]; then
  echo "ERROR: destination is not an existing directory: $destination" >&2
  exit 1
fi

script_dir="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(dirname -- "$script_dir")"
if [ -z "$source_path" ]; then
  if ! command -v nix >/dev/null 2>&1; then
    echo "ERROR: nix is required to build the Compound Engineering Amp plugin" >&2
    exit 1
  fi
  source_path="$(
    nix --accept-flake-config build \
      "path:$repo_root#compound-engineering-amp-plugin" \
      --no-link \
      --print-out-paths
  )"
fi

if [ ! -d "$source_path" ]; then
  echo "ERROR: plugin source is not a directory: $source_path" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required to validate and export the plugin" >&2
  exit 1
fi

python3 - "$source_path" "$SOURCE_REPOSITORY" "$PLUGIN_NAME" "$MANIFEST_NAME" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
expected_repository = sys.argv[2]
expected_plugin = sys.argv[3]
manifest_name = sys.argv[4]

required = [root / "index.ts", root / "LICENSE", root / manifest_name, root / "skills"]
if any(not path.exists() for path in required):
    raise SystemExit(f"plugin source is incomplete: {root}")

try:
    manifest = json.loads((root / manifest_name).read_text(encoding="utf-8"))
except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
    raise SystemExit(f"invalid plugin manifest: {error}") from error

if manifest.get("schemaVersion") != 1:
    raise SystemExit("unsupported plugin manifest schema")
if manifest.get("source", {}).get("repository") != expected_repository:
    raise SystemExit("plugin manifest belongs to another source")
if manifest.get("pluginName") != expected_plugin:
    raise SystemExit("plugin manifest has the wrong plugin name")

skills = manifest.get("skills")
name_pattern = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
if not isinstance(skills, list) or not skills:
    raise SystemExit("plugin manifest contains no skills")
bundled = [mapping.get("bundled") for mapping in skills if isinstance(mapping, dict)]
if len(bundled) != len(skills) or any(
    not isinstance(name, str) or name_pattern.fullmatch(name) is None for name in bundled
):
    raise SystemExit("plugin manifest contains invalid bundled skill names")
if len(bundled) != len(set(bundled)):
    raise SystemExit("plugin manifest contains duplicate bundled skill names")

actual = sorted(path.name for path in (root / "skills").iterdir() if path.is_dir())
if actual != sorted(bundled):
    raise SystemExit("plugin skill directories do not match the manifest")
for name in bundled:
    skill_file = root / "skills" / name / "SKILL.md"
    content = skill_file.read_text(encoding="utf-8")
    if re.search(rf'^name:\s*["\']?{re.escape(name)}["\']?\s*$', content, re.MULTILINE) is None:
        raise SystemExit(f"skill directory/frontmatter mismatch: {name}")

for path in root.rglob("*"):
    if path.is_symlink():
        raise SystemExit(f"plugin export contains a symbolic link: {path}")
    if path.is_file():
        try:
            path.read_text(encoding="utf-8")
        except UnicodeDecodeError as error:
            raise SystemExit(f"plugin export contains a non-UTF-8 file: {path}") from error
PY

target="$destination/$PLUGIN_NAME"
if [ -e "$destination/$PLUGIN_NAME.ts" ] || [ -e "$destination/$PLUGIN_NAME.js" ]; then
  echo "ERROR: refusing to collide with an existing single-file plugin named $PLUGIN_NAME" >&2
  exit 1
fi
if [ -L "$target" ]; then
  echo "ERROR: refusing to replace a symbolic-link destination plugin: $target" >&2
  exit 1
fi
if [ -e "$target" ]; then
  if [ ! -f "$target/$MANIFEST_NAME" ]; then
    echo "ERROR: refusing to replace unmanaged destination plugin: $target" >&2
    exit 1
  fi
  python3 - "$target/$MANIFEST_NAME" "$SOURCE_REPOSITORY" "$PLUGIN_NAME" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    manifest = json.loads(path.read_text(encoding="utf-8"))
except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
    raise SystemExit(f"invalid ownership manifest {path}: {error}") from error
if manifest.get("schemaVersion") != 1:
    raise SystemExit(f"unsupported ownership manifest schema in {path}")
if manifest.get("source", {}).get("repository") != sys.argv[2]:
    raise SystemExit(f"ownership manifest belongs to another source: {path}")
if manifest.get("pluginName") != sys.argv[3]:
    raise SystemExit(f"ownership manifest belongs to another plugin: {path}")
PY
fi

stage="$(mktemp -d "$destination/.compound-engineering-plugin-export.XXXXXX")"
cleanup() {
  chmod -R u+rwX "$stage" 2>/dev/null || true
  rm -rf -- "$stage"
}
trap cleanup EXIT
cp -aL --no-preserve=ownership "$source_path/." "$stage/"
chmod -R u+rwX "$stage"
rm -rf -- "$target"
mv "$stage" "$target"
trap - EXIT

revision="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["source"]["revision"])' "$target/$MANIFEST_NAME")"
skill_count="$(find "$target/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)"
printf 'Exported Amp plugin %s with %d Compound Engineering skills to %s\n' "$PLUGIN_NAME" "$skill_count" "$destination"
printf 'Pinned upstream revision: %s\n' "$revision"
printf 'Review and publish changes from the Global Plugins repository checkout.\n'
