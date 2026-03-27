{ pkgs, lib ? pkgs.lib }:
let
  zshPath = "${pkgs.zsh}/bin/zsh";
  aliasesBody = ''
    if command -v emacsclient >/dev/null 2>&1; then
      alias e='emacsclient -nw'
    elif command -v mg >/dev/null 2>&1; then
      alias e='mg -n'
    else
      alias e='vi'
    fi
  '';
  agentWrappersBody = ''
    alias claude='claude --dangerously-skip-permissions --model opus'
    alias codex='codex --yolo'
  '';
  tmuxHelpersBody = ''
    _tmux-set-colour() {
      if command -v md5 >/dev/null 2>&1; then
        export TMUX_COLOUR="colour$((0x$(md5 -qs "$1" | cut -c1-2)))"
      elif command -v md5sum >/dev/null 2>&1; then
        export TMUX_COLOUR="colour$((0x$(printf '%s' "$1" | md5sum | cut -c1-2)))"
      else
        export TMUX_COLOUR="colour241"
      fi
    }

    _tmux-apply-colour() {
      local socket="$1"
      tmux -L "$socket" start-server 2>/dev/null || true
      tmux -L "$socket" source-file "$HOME/.tmux.conf" 2>/dev/null || true
      tmux -L "$socket" set-option -g extended-keys on 2>/dev/null || true
      tmux -L "$socket" set-option -g extended-keys-format csi-u 2>/dev/null || true
      tmux -L "$socket" set-environment -g TZ "Europe/Stockholm" 2>/dev/null || true
      tmux -L "$socket" set-environment -g TMUX_COLOUR "''${TMUX_COLOUR:-colour241}" 2>/dev/null || true
      tmux -L "$socket" set-option -g status-bg "''${TMUX_COLOUR:-colour241}" 2>/dev/null || true
      tmux -L "$socket" set-option -g status-right "#h #(env TZ=Europe/Stockholm date +%%Y-%%m-%%d\\ %%H:%%M)" 2>/dev/null || true
    }

    tmux-default() {
      _tmux-set-colour default
      _tmux-apply-colour default
      tmux -L default new-session -A -s default "$@"
    }

    tmux-here() {
      local s="''${PWD##*/}"
      s="''${s//[^A-Za-z0-9_.-]/_}"
      _tmux-set-colour "''${s}@''${HOST%%.*}"
      _tmux-apply-colour "$s"
      tmux -L "$s" new-session -A -s "$s" "$@"
    }
  '';
  zshPrelude = ''
    # Home Manager managed interactive shell additions for toolnix hosts.

    export SHELL="${zshPath}"
    export HISTFILE="$HOME/.zsh_history"
    export HISTSIZE=100000
    export SAVEHIST=100000
    setopt prompt_subst
    setopt appendhistory
    bindkey -e
    export WORDCHARS=""

    setopt histignorealldups
    setopt histignorespace
    setopt histfindnodups
    setopt incappendhistory
    setopt sharehistory

    stty -ixon -ixoff 2>/dev/null || true

    autoload -Uz colors && colors
    autoload -Uz add-zsh-hook
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:git:*' formats ' (%b)'
    zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'
    zstyle ':vcs_info:*' nvcsformats ""

    if (( ! $+commands[bat] && $+commands[batcat] )); then
      alias bat='batcat'
    fi

    _toolnix_precmd_vcs_info() { vcs_info; }
    add-zsh-hook precmd _toolnix_precmd_vcs_info

    PROMPT='%n@%m:%~''${vcs_info_msg_0_}%# '
  '';
  zshBody = lib.concatStringsSep "\n" [
    aliasesBody
    agentWrappersBody
    tmuxHelpersBody
  ];
  tmuxConf = ''
    set-option -g default-shell ${zshPath}
    set-option -g default-command '${zshPath} -il'

    set-option -g prefix C-a
    unbind-key C-b
    bind-key C-a send-prefix
    bind-key a send-prefix

    set-option -ag terminal-overrides ",alacritty:RGB"
    set-option -g extended-keys on
    set-option -g extended-keys-format csi-u
    set-option -g status-bg colour241
    set-option -g status-right '#h #(env TZ=Europe/Stockholm date +%%Y-%%m-%%d\ %%H:%%M)'
    set-option -g history-limit 10000
    setw -g aggressive-resize on

    set-option -g update-environment "DISPLAY WINDOWID SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION KRB5CCNAME TMUX_COLOUR"

    bind-key C-c new-window
    bind-key C-d detach-client
    bind-key C-l last-window
    bind-key C-n next-window
    bind-key C-p previous-window
    bind-key C-r refresh-client
  '';
in {
  env = {
    TZ = "Europe/Stockholm";
  };

  inherit zshBody tmuxConf;

  renderProjectShell = {
    includeAliases ? true,
    includeAgentWrappers ? true,
    includeTmuxHelpers ? true,
  }:
    lib.concatStringsSep "\n" (
      lib.optionals includeAliases [ aliasesBody ]
      ++ lib.optionals includeAgentWrappers [ agentWrappersBody ]
      ++ lib.optionals includeTmuxHelpers [ tmuxHelpersBody ]
    );

  renderZshRc = { extraBody ? "" }:
    ''
${zshPrelude}

${zshBody}
'' + (if extraBody == "" then "" else ''
${extraBody}
'' ) + ''
      [[ -r "$HOME/.zsh/zshlocal.sh" ]] && source "$HOME/.zsh/zshlocal.sh"
    '';

  renderTmuxConf = { extraBody ? "" }:
    tmuxConf + (if extraBody == "" then "" else ''

${extraBody}
'' );
}
