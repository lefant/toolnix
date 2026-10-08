#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
helper=${TOOLNIX_TEST_HELPER:-$root/scripts/agent-adoption.sh}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME/.claude" "$HOME/.codex" "$tmp/foreign"
printf 'secret' > "$HOME/.claude/auth.json"
printf 'history' > "$HOME/.codex/history.jsonl"
printf 'original' > "$HOME/.claude/settings.json"
printf 'foreign' > "$tmp/foreign/file"
ln -s "$tmp/foreign/file" "$HOME/.codex/config.toml"
ln -s "$tmp/missing" "$HOME/.claude/CLAUDE.md"
mkdir "$HOME/.claude/skills"
printf 'tree' > "$HOME/.claude/skills/file"
export TOOLNIX_AGENT_BACKUP_ROOT="$tmp/backups"
DRY_RUN=1 DRY_RUN_CMD=echo bash "$helper" .claude/settings.json
test "$(cat "$HOME/.claude/settings.json")" = original
test ! -e "$tmp/backups"
DRY_RUN_CMD=echo bash "$helper" .claude/settings.json
test "$(cat "$HOME/.claude/settings.json")" = original
test ! -e "$tmp/backups"
mkdir -p "$tmp/real-backups"
ln -s "$tmp/real-backups" "$tmp/linked-backups"
if TOOLNIX_AGENT_BACKUP_ROOT="$tmp/linked-backups/nested" bash "$helper" .claude/settings.json; then
  echo 'symlink backup ancestor was accepted' >&2; exit 1
fi
test "$(cat "$HOME/.claude/settings.json")" = original
test ! -e "$tmp/real-backups/nested"
mkdir -p "$tmp/foreign/parent"
printf 'parent' > "$tmp/foreign/parent/settings.json"
ln -s "$tmp/foreign/parent" "$HOME/.claude/linked"
if bash "$helper" .claude/linked/settings.json; then
  echo 'symlink target parent was accepted' >&2; exit 1
fi
test "$(cat "$tmp/foreign/parent/settings.json")" = parent
mkdir "$tmp/bin"
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/mv"
chmod +x "$tmp/bin/mv"
if TOOLNIX_AGENT_BACKUP_ROOT="$tmp/failed-backups" PATH="$tmp/bin:$PATH" bash "$helper" .claude/settings.json; then
  echo 'failed rename was accepted' >&2; exit 1
fi
test "$(cat "$HOME/.claude/settings.json")" = original
bash "$helper" .claude/settings.json .codex/config.toml .claude/CLAUDE.md .claude/skills .pi/agent/settings.json
test ! -e "$HOME/.claude/settings.json"
test ! -L "$HOME/.codex/config.toml"
test "$(cat "$tmp/foreign/file")" = foreign
test "$(cat "$HOME/.claude/auth.json")" = secret
test "$(cat "$HOME/.codex/history.jsonl")" = history
test "$(find "$tmp/backups" -name manifest -type f | wc -l)" -eq 1
test "$(stat -c %a "$tmp/backups")" = 700
test "$(find "$tmp/backups" -name settings.json -type f | wc -l)" -eq 1
test "$(find "$tmp/backups" -name config.toml -type l | wc -l)" -eq 1
test "$(find "$tmp/backups" -name CLAUDE.md -type l | wc -l)" -eq 1
test "$(find "$tmp/backups" -name file -type f | wc -l)" -eq 1
bash "$helper" .claude/settings.json .codex/config.toml
test "$(find "$tmp/backups" -name manifest | wc -l)" -eq 1
printf 'second' > "$HOME/.claude/settings.json"
bash "$helper" .claude/settings.json
test "$(find "$tmp/backups" -name manifest | wc -l)" -eq 2
if [[ -n "${TOOLNIX_TEST_MANAGED_STORE:-}" ]]; then
  store=$TOOLNIX_TEST_MANAGED_STORE
else
  mkdir -p "$tmp/test-home-manager-files/.claude"
  printf managed > "$tmp/test-home-manager-files/.claude/settings.json"
  store=$(nix store add-path "$tmp/test-home-manager-files")
fi
ln -s "$store/.claude/settings.json" "$HOME/.claude/settings.json"
bash "$helper" .claude/settings.json
test "$(readlink "$HOME/.claude/settings.json")" = "$store/.claude/settings.json"
test "$(find "$tmp/backups" -name manifest | wc -l)" -eq 2
rm "$HOME/.claude/settings.json"
printf 'failure' > "$HOME/.claude/settings.json"
if TOOLNIX_AGENT_BACKUP_ROOT="$HOME/.claude/auth.json/invalid" bash "$helper" .claude/settings.json; then
  echo 'backup failure was ignored' >&2; exit 1
fi
test "$(cat "$HOME/.claude/settings.json")" = failure
echo 'agent adoption tests passed'
