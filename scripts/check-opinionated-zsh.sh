#!/usr/bin/env bash
set -euo pipefail

zsh -ilc '
  whence -w compinit >/dev/null
  typeset -p _comps >/dev/null 2>&1
  test -r "$HOME/.zsh/completion"
  grep -q "special-dirs true" "$HOME/.zsh/completion"
  zstyle -L ":completion:*" | grep -q "special-dirs true"
  echo "ok: compinit + tracked completion defaults active"
'
