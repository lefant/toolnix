{ config, inputs, ... }:
{
  perSystem = { pkgs, system, ... }:
    let
      lib = pkgs.lib;
      browser = import ../../modules/shared/browser-tools.nix { inherit pkgs lib inputs; };
      home = (inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs { inherit system; };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          config.toolnix.profiles.homeManager.agentsModule
          {
            home.username = "browser-check";
            home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/browser-check" else "/home/browser-check";
            home.stateVersion = "25.05";
            toolnix.agentBrowser.enable = true;
          }
        ];
      }).config;
      packages = home.home.packages;
      checked = assert browser.agentBrowser.packages == [ ];
        assert !(home.home.sessionVariables ? AGENT_BROWSER_EXECUTABLE_PATH);
        assert !(home.home.sessionVariables ? TOOLNIX_CHROMIUM);
        assert !(lib.any (pkg: lib.elem (lib.getName pkg) [ "agent-browser" "vhs" "chromium" ]) packages);
        true;
    in {
      checks.browser-platform = assert checked; pkgs.runCommand "browser-platform-check" { } ''
        touch "$out"
      '';
    };
}
