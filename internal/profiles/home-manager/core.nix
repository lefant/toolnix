{ config, lib, pkgs, inputs, toolnixFeatures, ... }:
let
  toolnixRoot = ../../..;
  cfg = config.toolnix;
  opinionated = toolnixFeatures.opinionatedShell.data { inherit pkgs; };
  hostControl = toolnixFeatures.hostControl.data { inherit pkgs; };
  agentBrowser = toolnixFeatures.agentBrowser.data { inherit pkgs lib inputs; };
  browserTools = toolnixFeatures.browserTools.data { inherit pkgs lib inputs; };
  hitlBrowserAutomation = toolnixFeatures.hitlBrowserAutomation.data { inherit pkgs lib inputs; };
  hitlEnabled = cfg.hitlBrowserAutomation.enable or false;
  browserEnabled = cfg.browserTools.enable || hitlEnabled;
in {
  options.toolnix.hostName = lib.mkOption {
    type = lib.types.str;
    default = "toolnix";
    description = "Short host label used in the tmux status line.";
  };
  config = {
    programs.home-manager.enable = true;
    home.packages =
      lib.optionals (browserEnabled && !cfg.agentBrowser.enable) agentBrowser.packages
      ++ lib.optionals cfg.browserTools.enable browserTools.browserTools.packages
      ++ lib.optionals hitlEnabled hitlBrowserAutomation.packages;
    home.sessionVariables = opinionated.env
      // lib.optionalAttrs browserEnabled agentBrowser.env
      // lib.optionalAttrs cfg.browserTools.enable browserTools.browserTools.env
      // lib.optionalAttrs hitlEnabled hitlBrowserAutomation.env;

    home.file.".zshrc".text = ''
      source ~/.zsh/zshrc.sh
    '';
    home.file.".zsh/zshrc.sh".text = opinionated.renderZshRc {
      extraBody = lib.concatStringsSep "\n" (
        [ hostControl.tmuxMetaBody ]
        ++ lib.optionals cfg.enableHostControl [ hostControl.controlHostBody ]
      );
    };
    home.file.".zsh/completion".source = ../../../home-manager/files/zsh-completion;
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
    home.file.".gitconfig".source = ../../../home-manager/files/gitconfig;
    home.file.".gitconfig.altego".source = ../../../home-manager/files/gitconfig.altego;
    home.file.".gitconfig.gh-auth".source = ../../../home-manager/files/gitconfig.gh-auth;
    home.file.".ssh/config".source = ../../../home-manager/files/ssh-config;
    home.file.".claude/settings.json".source = lib.mkForce ../../../agents/claude/templates/settings.json;
    home.file.".codex/config.toml".source = lib.mkForce ../../../agents/codex/templates/config.toml;
    home.file.".tmux.conf".text = opinionated.renderTmuxConf { };
    home.file.".tmux.conf.meta".text = hostControl.tmuxConf;

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
