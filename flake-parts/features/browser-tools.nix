{ config, inputs, ... }:
let
  flakeConfig = config;
  browserToolsData = import ../../modules/shared/browser-tools.nix;
in {
  config = {
    perSystem =
    { pkgs, system, ... }:
    let
      lib = pkgs.lib;
      browserTools = browserToolsData { inherit pkgs lib inputs; };
      mkHome = extraModule:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs { inherit system; };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            flakeConfig.toolnix.profiles.homeManager.defaultModule
            {
              home.username = "exedev";
              home.homeDirectory = "/tmp/toolnix-check";
              home.stateVersion = "25.05";
              toolnix.hostName = "toolnix-check";
            }
            extraModule
          ];
        };
      mkDevenv = extraModule:
        lib.evalModules {
          specialArgs = { inherit pkgs inputs; };
          modules = [
            ({ lib, ... }: {
              options.packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
              };
              options.env = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = { };
              };
              options.enterShell = lib.mkOption {
                type = lib.types.lines;
                default = "";
              };
            })
            flakeConfig.toolnix.profiles.devenv.defaultModule
            extraModule
          ];
        };
      defaultHome = mkHome { };
      agentBrowserHome = mkHome {
        toolnix.agentBrowser.enable = true;
      };
      browserToolsHome = mkHome {
        toolnix.browserTools.enable = true;
      };
      defaultDevenv = mkDevenv { };
      agentBrowserDevenv = mkDevenv {
        toolnix.agentBrowser.enable = true;
      };
      browserToolsDevenv = mkDevenv {
        toolnix.browserTools.enable = true;
      };
      defaultPackages = defaultHome.config.home.packages;
      agentBrowserPackages = agentBrowserHome.config.home.packages;
      browserToolsPackages = browserToolsHome.config.home.packages;
      defaultDevenvPackages = defaultDevenv.config.packages;
      agentBrowserDevenvPackages = agentBrowserDevenv.config.packages;
      browserToolsDevenvPackages = browserToolsDevenv.config.packages;
      agentBrowserEnv = agentBrowserHome.config.home.sessionVariables;
      browserToolsEnv = browserToolsHome.config.home.sessionVariables;
      agentBrowserDevenvEnv = agentBrowserDevenv.config.env;
      browserToolsDevenvEnv = browserToolsDevenv.config.env;
      hasPackage = pkg: packages: lib.any (candidate: candidate == pkg) packages;
      hasAgentBrowserChromiumEnv = env:
        (env.AGENT_BROWSER_EXECUTABLE_PATH or null) == browserTools.chromiumExecutable;
    in {
      checks.browser-tools-packages = pkgs.runCommand "browser-tools-packages-check" { } ''
        set -euo pipefail

        ${lib.optionalString (hasPackage browserTools.agentBrowserPackage defaultPackages || hasPackage browserTools.agentBrowserPackage defaultDevenvPackages) ''
          echo "agent-browser should not be installed by default" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage browserTools.vhsPackage defaultPackages || hasPackage browserTools.vhsPackage defaultDevenvPackages) ''
          echo "vhs should not be installed by default" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage pkgs.chromium defaultPackages || hasPackage pkgs.chromium defaultDevenvPackages) ''
          echo "chromium should not be installed by default" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage browserTools.agentBrowserPackage agentBrowserPackages) || !(hasPackage browserTools.agentBrowserPackage agentBrowserDevenvPackages)) ''
          echo "agent-browser should be installed when toolnix.agentBrowser.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage browserTools.vhsPackage agentBrowserPackages || hasPackage browserTools.vhsPackage agentBrowserDevenvPackages) ''
          echo "vhs should not be installed when only toolnix.agentBrowser.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage browserTools.agentBrowserPackage browserToolsPackages) || !(hasPackage browserTools.agentBrowserPackage browserToolsDevenvPackages)) ''
          echo "agent-browser should be installed when toolnix.browserTools.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage browserTools.vhsPackage browserToolsPackages) || !(hasPackage browserTools.vhsPackage browserToolsDevenvPackages)) ''
          echo "vhs should be installed when toolnix.browserTools.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage pkgs.chromium browserToolsPackages) || !(hasPackage pkgs.chromium browserToolsDevenvPackages)) ''
          echo "chromium should be installed when toolnix.browserTools.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasAgentBrowserChromiumEnv agentBrowserEnv) || !(hasAgentBrowserChromiumEnv agentBrowserDevenvEnv)) ''
          echo "agent-browser env should point at toolnix pkgs.chromium when toolnix.agentBrowser.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasAgentBrowserChromiumEnv browserToolsEnv) || !(hasAgentBrowserChromiumEnv browserToolsDevenvEnv)) ''
          echo "agent-browser env should point at toolnix pkgs.chromium when toolnix.browserTools.enable = true" >&2
          exit 1
        ''}

        touch "$out"
      '';
    };

    toolnix.features.browserTools = {
      data = browserToolsData;

      homeManagerOptionModule = { lib, ... }: {
        options.toolnix.browserTools.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable opt-in Nix-managed browser automation tools: agent-browser, vhs, and Chromium.";
        };
      };

      devenvOptionModule = { lib, ... }: {
        options.toolnix.browserTools.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable opt-in Nix-managed browser automation tools in the project shell: agent-browser, vhs, and Chromium.";
        };
      };
    };
  };
}
