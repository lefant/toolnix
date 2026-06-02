# 2026-06-02 tmux-here dotted repo names

## Summary

Fixed `tmux-here` for repositories whose directory names contain dots, such as
`e.lefant.net`.

## Problem

`tmux-here` derived the tmux socket/session name from the current directory and
allowed dots:

```zsh
s="${s//[^A-Za-z0-9_.-]/_}"
```

On `lefant-e-lefant-net.exe.xyz`, running from
`~/git/lefant/e.lefant.net` produced a dotted tmux target. Tmux parses dotted
targets as `session.window.pane`, which caused attach failures like:

```text
duplicate session: lefant_github_io
can't find pane: github.io
```

## Change

`modules/shared/opinionated-shell.nix` now sanitizes dots to underscores for
`tmux-here` socket/session names:

```zsh
s="${s//[^A-Za-z0-9_-]/_}"
```

So a repository named `e.lefant.net` gets the exact tmux session/socket name:

```text
e_lefant_net
```

## Validation

Validated the rendered `zshBody` from the local checkout and exercised
`tmux-here` in a pseudo-terminal from a temporary `e.lefant.net` directory.
The proof left the expected tmux session running:

```text
e_lefant_net: 1 windows
```

Also updated `scripts/check-opinionated-tmux.sh` to use a dotted fixture
directory and expect the sanitized socket/session name `e_lefant_net`.

Note: running the check script directly before activating this new Toolnix
revision still tests the currently installed shell helper and can reproduce the
old failure. After this revision is activated, the check covers the regression.
