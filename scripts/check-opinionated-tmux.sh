#!/usr/bin/env bash
set -euo pipefail

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 1
  fi
}

print_log_tail() {
  local log_file="$1"
  if [ -f "$log_file" ]; then
    printf '\n--- tmux probe tail ---\n' >&2
    tail -n 40 "$log_file" >&2 || true
  fi
}

require_cmd tmux
require_cmd zsh
require_cmd script
require_cmd timeout

host_short="$(hostname -s 2>/dev/null || hostname)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/toolnix-opinionated-tmux-XXXXXX")"
socket="$(basename "$work_dir")"
log_file="${TMPDIR:-/tmp}/${socket}.typescript"

cleanup() {
  tmux -L "$socket" kill-server >/dev/null 2>&1 || true
  rm -rf "$work_dir" "$log_file"
}
trap cleanup EXIT

if command -v md5 >/dev/null 2>&1; then
  expected_colour="colour$((0x$(md5 -qs "${socket}@${host_short}" | cut -c1-2)))"
elif command -v md5sum >/dev/null 2>&1; then
  expected_colour="colour$((0x$(printf '%s' "${socket}@${host_short}" | md5sum | cut -c1-2)))"
else
  expected_colour="colour241"
fi

printf -v inner_cmd 'cd %q && whence -w tmux-here >/dev/null && tmux-here' "$work_dir"
printf -v probe_cmd 'TERM=xterm-256color zsh -ilc %q' "$inner_cmd"

tmux -L "$socket" kill-server >/dev/null 2>&1 || true

set +e
TERM=xterm-256color timeout 4 script -qefc "$probe_cmd" "$log_file" >/dev/null 2>&1
probe_rc=$?
set -e

case "$probe_rc" in
  0|124) ;;
  *)
    echo "ERROR: tmux-here first-attach probe failed with exit code $probe_rc" >&2
    print_log_tail "$log_file"
    exit 1
    ;;
esac

if ! tmux -L "$socket" has-session -t "$socket" 2>/dev/null; then
  echo "ERROR: tmux-here did not leave the expected session running on socket $socket" >&2
  print_log_tail "$log_file"
  exit 1
fi

status_bg="$(tmux -L "$socket" show -gv status-bg 2>/dev/null || true)"
session_colour="$(tmux -L "$socket" show-environment -g TMUX_COLOUR 2>/dev/null | sed 's/^TMUX_COLOUR=//' || true)"

if [ "$session_colour" != "$expected_colour" ]; then
  echo "ERROR: expected TMUX_COLOUR $expected_colour but saw ${session_colour:-<unset>}" >&2
  print_log_tail "$log_file"
  exit 1
fi

if [ "$status_bg" != "$expected_colour" ]; then
  echo "ERROR: expected first-attach status-bg $expected_colour but saw ${status_bg:-<unset>}" >&2
  print_log_tail "$log_file"
  exit 1
fi

echo "ok: tmux-here first attach uses derived status-bg $expected_colour"
