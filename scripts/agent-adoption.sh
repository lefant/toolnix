#!/usr/bin/env bash
# Called before Home Manager's checkLinkTargets; arguments are exact managed targets.
set -euo pipefail
umask 077
# Home Manager exports DRY_RUN_CMD=echo for dry runs (and DRY_RUN for newer entries).
if [[ -v DRY_RUN || -n "${DRY_RUN_CMD:-}" ]]; then
  echo 'Agent adoption: dry run; no files moved' >&2
  exit 0
fi
root=${TOOLNIX_AGENT_BACKUP_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/toolnix/agent-backups}
batch=''
for relative in "$@"; do
  case "$relative" in
    /*|*'..'*|'') echo "invalid managed target: $relative" >&2; exit 1 ;;
  esac
  parent="$HOME"
  IFS=/ read -r -a parts <<< "$relative"
  for ((i=0; i<${#parts[@]}-1; i++)); do
    parent="$parent/${parts[i]}"
    if [[ -L "$parent" ]]; then
      echo "Agent adoption stopped: symlink parent $parent requires manual resolution" >&2
      exit 1
    fi
  done
  target="$HOME/$relative"
  if [[ ! -e "$target" && ! -L "$target" ]]; then continue; fi
  # Do not follow the link: only a live, exact home-files generation entry is ours.
  if [[ -L "$target" && -e "$target" ]]; then
    link=$(readlink "$target")
    case "$link" in
      /nix/store/*-home-manager-files/"$relative") continue ;;
    esac
  fi
  if [[ -z "$batch" ]]; then
    ancestor=$root
    while [[ "$ancestor" != / && "$ancestor" != . ]]; do
      if [[ -L "$ancestor" ]]; then
        echo "Agent backup path must not contain a symlink: $ancestor" >&2
        exit 1
      fi
      ancestor=$(dirname -- "$ancestor")
    done
    mkdir -p -- "$root" || exit 1
    chmod 700 -- "$root" || exit 1
    batch=$(mktemp -d "$root/adoption.XXXXXXXXXX") || exit 1
    : > "$batch/manifest"
  fi
  destination="$batch/$relative"
  mkdir -p -- "${destination%/*}" || exit 1
  # Rename preserves symlinks (including dangling links) without visiting their destinations.
  if ! mv -- "$target" "$destination"; then
    echo "Agent adoption stopped: could not back up $target; prior backups: $batch/manifest" >&2
    exit 1
  fi
  printf '%s\n' "$relative" >> "$batch/manifest"
  echo "Agent configuration backed up: $target -> $destination (manifest: $batch/manifest)" >&2
done
