{ pkgs }:
let
  zshPath = "${pkgs.zsh}/bin/zsh";
in {
  zshBody = ''
    export HACKBOX_CTRL_INVENTORY_ROOT="''${HACKBOX_CTRL_INVENTORY_ROOT:-$HOME/git/lefant/hackbox-ctrl-inventory}"

    target-entry() {
      "$HACKBOX_CTRL_INVENTORY_ROOT/tooling/hackbox-ctrl-utils/scripts/target-ssh.sh" "$@"
    }

    targets() {
      "$HACKBOX_CTRL_INVENTORY_ROOT/tooling/hackbox-ctrl-utils/scripts/target-ssh.sh" --list
    }

    tmux-meta() {
      export TMUX_COLOUR="colour255"
      tmux -L meta -f "$HOME/.tmux.conf.meta" start-server 2>/dev/null || true
      tmux -L meta source-file "$HOME/.tmux.conf.meta" 2>/dev/null || true
      tmux -L meta set-option -g extended-keys on 2>/dev/null || true
      tmux -L meta set-option -g extended-keys-format csi-u 2>/dev/null || true
      tmux -L meta set-environment -g TZ "Europe/Stockholm" 2>/dev/null || true
      tmux -L meta set-environment -g TMUX_COLOUR "colour255" 2>/dev/null || true
      tmux -L meta set-option -g status-bg "white" 2>/dev/null || true
      tmux -L meta set-option -g status-right "#h #(env TZ=Europe/Stockholm date +%%Y-%%m-%%d\\ %%H:%%M)" 2>/dev/null || true
      tmux -L meta -f "$HOME/.tmux.conf.meta" new-session -A -s meta "$@"
    }
  '';

  tmuxConf = ''
    set-option -g default-shell ${zshPath}
    set-option -g default-command '${zshPath} -il'

    # fix prefix to be C-o for meta session
    set-option -g prefix C-o
    unbind-key C-b
    bind-key C-o send-prefix
    bind-key o send-prefix

    set-option -ag terminal-overrides ",alacritty:RGB"
    set-option -g extended-keys on
    set-option -g extended-keys-format csi-u
    set-option -g status-bg white
    set-option -g status-right '#h #(env TZ=Europe/Stockholm date +%%Y-%%m-%%d\ %%H:%%M)'
    set-option -g history-limit 10000
    setw -g aggressive-resize on

    bind-key C-c new-window
    bind-key C-d detach-client
    bind-key C-l last-window
    bind-key C-n next-window
    bind-key C-p previous-window
    bind-key C-r refresh-client
  '';
}
