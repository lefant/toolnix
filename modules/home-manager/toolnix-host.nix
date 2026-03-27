{ config, lib, pkgs, inputs, ... }:
let
  toolnixRoot = ../..;
  cfg = config.toolnix;
  required = import ../shared/required-baseline.nix { inherit pkgs; };
  agent = import ../shared/agent-baseline.nix { inherit pkgs lib inputs; };
  opinionated = import ../shared/opinionated-shell.nix { inherit pkgs; };
  hostControl = import ../shared/host-control.nix { inherit pkgs; };
in {
  options.toolnix.hostName = lib.mkOption {
    type = lib.types.str;
    default = "toolnix";
    description = "Short host label used in the tmux status line.";
  };

  options.toolnix.enableHostControl = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable host/control-only shell helpers such as tmux-meta.";
  };

  options.toolnix.enableAgentBaseline = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable the shared agent baseline on Home Manager hosts.";
  };

  config = {
    programs.home-manager.enable = true;

    home.packages =
      required.homePackages
      ++ lib.optionals cfg.enableAgentBaseline agent.packages;
    home.sessionVariables =
      required.env
      // opinionated.env
      // lib.optionalAttrs cfg.enableAgentBaseline agent.env;

    home.file.".zshrc".text = ''
      source ~/.zsh/zshrc.sh
    '';
    home.file.".zsh/zshrc.sh".text = opinionated.renderZshRc {
      extraBody = lib.optionalString cfg.enableHostControl hostControl.zshBody;
    };
    home.file.".zsh/zshlocal.sh".text = ''
      # Keep this minimal by default. Source runtime credentials until they
      # move to a better injection path.
      if [ -f "$HOME/.env.toolnix" ]; then
        set -a
        . "$HOME/.env.toolnix"
        set +a
      elif [ -f "$HOME/.env.toolbox" ]; then
        set -a
        . "$HOME/.env.toolbox"
        set +a
      fi
    '';
    home.file.".zshenv".text = ''
      if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi
    '';
    home.file.".gitconfig".source = ../../home-manager/files/gitconfig;
    home.file.".gitconfig.altego".source = ../../home-manager/files/gitconfig.altego;
    home.file.".gitconfig.gh-auth".source = ../../home-manager/files/gitconfig.gh-auth;
    home.file.".ssh/config".source = ../../home-manager/files/ssh-config;
    home.file.".tmux.conf".text = opinionated.renderTmuxConf { };
    home.file.".tmux.conf.meta" = lib.mkIf cfg.enableHostControl {
      text = hostControl.tmuxConf;
    };

    home.activation.seedClaudeRuntimeState =
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        claude_template="${toolnixRoot}/agents/claude/templates/dot-claude.json"
        claude_json="${config.home.homeDirectory}/.claude.json"
        tmp_json="$(mktemp)"

        if [ -f "$claude_template" ]; then
          if [ -f "$claude_json" ]; then
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$claude_template" "$claude_json" > "$tmp_json"
          else
            cp "$claude_template" "$tmp_json"
          fi

          ${pkgs.coreutils}/bin/install -m 600 "$tmp_json" "$claude_json"
          rm -f "$tmp_json"
        fi
      '';
  };
}
