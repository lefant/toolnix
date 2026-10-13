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
      browserCount = lib.length (lib.filter (pkg: pkg == browser.agentBrowserPackage) packages);
      expected = if pkgs.stdenv.hostPlatform.isDarwin
        then "${browser.chromium}/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
        else "${pkgs.chromium}/bin/chromium";
      checked = assert browserCount == 1;
        assert home.home.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH == expected;
        assert home.home.sessionVariables.TOOLNIX_CHROMIUM == expected;
        assert !(lib.any (pkg: pkg == browser.vhsPackage || pkg == browser.chromium) packages);
        true;
    in {
      checks.browser-platform = assert checked; pkgs.runCommand "browser-platform-check" { } ''
        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          grep -F -- ${lib.escapeShellArg expected} ${browser.agentBrowserPackage}/bin/agent-browser
          test -x ${lib.escapeShellArg expected}
        ''}
        touch "$out"
      '';
    };
}
