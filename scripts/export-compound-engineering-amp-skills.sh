#!/usr/bin/env bash
set -euo pipefail

readonly SOURCE_REPOSITORY="https://github.com/EveryInc/compound-engineering-plugin"
readonly MANIFEST_NAME="compound-engineering.lock.json"

usage() {
  cat <<'EOF'
Usage:
  scripts/export-compound-engineering-amp-skills.sh [--source <path>] <global-skills-checkout>

Export Toolnix's pinned Compound Engineering skills into an existing Amp Global
User or Workspace Skills repository checkout.

The command updates only skills owned by compound-engineering.lock.json. It does
not clone the destination, run Git commands, commit, or push.

Options:
  --source <path>  Use an already built skill collection instead of building the
                   compound-engineering-amp-skills flake package.
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
  echo "ERROR: a Global Skills repository checkout is required" >&2
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
    echo "ERROR: nix is required to build the Compound Engineering skill collection" >&2
    exit 1
  fi

  source_path="$(
    nix --accept-flake-config build \
      "path:$repo_root#compound-engineering-amp-skills" \
      --no-link \
      --print-out-paths
  )"
fi

if [ ! -d "$source_path" ]; then
  echo "ERROR: skill source is not a directory: $source_path" >&2
  exit 1
fi

if [ ! -f "$source_path/UPSTREAM_LICENSE" ]; then
  echo "ERROR: skill source is missing UPSTREAM_LICENSE: $source_path" >&2
  exit 1
fi

if [ ! -f "$source_path/UPSTREAM_REVISION" ]; then
  echo "ERROR: skill source is missing UPSTREAM_REVISION: $source_path" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required to validate and export the skills" >&2
  exit 1
fi

stage="$(mktemp -d)"
publish_stage=""
cleanup() {
  rm -rf -- "$stage"
  if [ -n "$publish_stage" ]; then
    rm -rf -- "$publish_stage"
  fi
}
trap cleanup EXIT

while IFS= read -r -d '' skill_dir; do
  name="$(basename -- "$skill_dir")"
  cp -aL --no-preserve=ownership "$skill_dir" "$stage/$name"
  chmod -R u+rwX "$stage/$name"
  cp --preserve=mode --no-preserve=ownership "$source_path/UPSTREAM_LICENSE" "$stage/$name/LICENSE"
  chmod u+rw "$stage/$name/LICENSE"
done < <(find "$source_path" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

mapfile -t skill_names < <(
  python3 - "$stage" <<'PY'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
skills = sorted(path for path in root.iterdir() if path.is_dir())
if not skills:
    raise SystemExit("generated collection contains no skill directories")

name_pattern = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
for skill in skills:
    skill_file = skill / "SKILL.md"
    if not skill_file.is_file():
        raise SystemExit(f"missing SKILL.md: {skill}")

    content = skill_file.read_text(encoding="utf-8")
    frontmatter = re.match(r"\A---\n(.*?)\n---(?:\n|\Z)", content, re.DOTALL)
    if frontmatter is None:
        raise SystemExit(f"missing YAML frontmatter: {skill_file}")

    match = re.search(r"^name:\s*['\"]?([^'\"\s]+)['\"]?\s*$", frontmatter.group(1), re.MULTILINE)
    if match is None:
        raise SystemExit(f"missing frontmatter name: {skill_file}")

    declared_name = match.group(1)
    if declared_name != skill.name:
        raise SystemExit(
            f"skill directory/frontmatter mismatch: {skill.name} != {declared_name}"
        )
    if name_pattern.fullmatch(skill.name) is None:
        raise SystemExit(f"invalid Amp skill name: {skill.name}")

    for path in skill.rglob("*"):
        if path.is_symlink():
            raise SystemExit(f"export contains a symbolic link: {path}")
        if path.is_file():
            try:
                path.read_text(encoding="utf-8")
            except UnicodeDecodeError as error:
                raise SystemExit(f"export contains a non-UTF-8 file: {path}") from error

    print(skill.name)
PY
)

manifest="$destination/$MANIFEST_NAME"
previous_names=()
if [ -e "$manifest" ]; then
  if [ ! -f "$manifest" ]; then
    echo "ERROR: ownership manifest is not a regular file: $manifest" >&2
    exit 1
  fi

  mapfile -t previous_names < <(
    python3 - "$manifest" "$SOURCE_REPOSITORY" <<'PY'
import json
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
expected_repository = sys.argv[2]
try:
    manifest = json.loads(path.read_text(encoding="utf-8"))
except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
    raise SystemExit(f"invalid ownership manifest {path}: {error}") from error

if manifest.get("schemaVersion") != 1:
    raise SystemExit(f"unsupported ownership manifest schema in {path}")
if manifest.get("source", {}).get("repository") != expected_repository:
    raise SystemExit(f"ownership manifest belongs to another source: {path}")

names = manifest.get("skills")
name_pattern = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
if not isinstance(names, list) or any(
    not isinstance(name, str) or name_pattern.fullmatch(name) is None
    for name in names
):
    raise SystemExit(f"ownership manifest contains invalid skill names: {path}")
if len(names) != len(set(names)):
    raise SystemExit(f"ownership manifest contains duplicate skill names: {path}")

for name in names:
    print(name)
PY
  )
fi

declare -A previously_managed=()
for name in "${previous_names[@]}"; do
  previously_managed["$name"]=1
done

for name in "${skill_names[@]}"; do
  if { [ -e "$destination/$name" ] || [ -L "$destination/$name" ]; } \
    && [ -z "${previously_managed[$name]:-}" ]; then
    echo "ERROR: refusing to replace unmanaged destination skill: $destination/$name" >&2
    exit 1
  fi
done

revision="$(<"$source_path/UPSTREAM_REVISION")"
if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: skill source has an invalid upstream revision: $revision" >&2
  exit 1
fi

python3 - "$stage/$MANIFEST_NAME" "$SOURCE_REPOSITORY" "$revision" "${skill_names[@]}" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
manifest = {
    "schemaVersion": 1,
    "source": {
        "repository": sys.argv[2],
        "revision": sys.argv[3],
    },
    "renderer": "toolnix",
    "skills": list(sys.argv[4:]),
}
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

publish_stage="$(mktemp -d "$destination/.compound-engineering-export.XXXXXX")"
for name in "${skill_names[@]}"; do
  mv "$stage/$name" "$publish_stage/$name"
done
mv "$stage/$MANIFEST_NAME" "$publish_stage/$MANIFEST_NAME"

declare -A current_skills=()
for name in "${skill_names[@]}"; do
  current_skills["$name"]=1
  rm -rf -- "${destination:?}/$name"
  mv "$publish_stage/$name" "$destination/$name"
done

for name in "${previous_names[@]}"; do
  if [ -z "${current_skills[$name]:-}" ]; then
    rm -rf -- "${destination:?}/$name"
  fi
done

mv "$publish_stage/$MANIFEST_NAME" "$manifest"
rmdir "$publish_stage"
publish_stage=""

printf 'Exported %d Compound Engineering skills to %s\n' "${#skill_names[@]}" "$destination"
printf 'Pinned upstream revision: %s\n' "$revision"
printf 'Review and publish changes from the Global Skills repository checkout.\n'
