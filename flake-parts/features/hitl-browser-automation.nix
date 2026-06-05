{ config, inputs, ... }:
let
  flakeConfig = config;
  hitlBrowserAutomationData = import ../../modules/shared/hitl-browser-automation.nix;
  browserToolsData = import ../../modules/shared/browser-tools.nix;
in {
  config = {
    perSystem =
    { pkgs, system, ... }:
    let
      lib = pkgs.lib;
      hitl = hitlBrowserAutomationData { inherit pkgs lib inputs; };
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
      hitlHome = mkHome { toolnix.hitlBrowserAutomation.enable = true; };
      defaultDevenv = mkDevenv { };
      hitlDevenv = mkDevenv { toolnix.hitlBrowserAutomation.enable = true; };
      defaultPackages = defaultHome.config.home.packages;
      hitlPackages = hitlHome.config.home.packages;
      defaultDevenvPackages = defaultDevenv.config.packages;
      hitlDevenvPackages = hitlDevenv.config.packages;
      hitlEnv = hitlHome.config.home.sessionVariables;
      hitlDevenvEnv = hitlDevenv.config.env;
      hasPackage = pkg: packages: lib.any (candidate: candidate == pkg) packages;
      hasBrowserEnv = env:
        (env.AGENT_BROWSER_EXECUTABLE_PATH or null) == browserTools.chromiumExecutable
        && (env.TOOLNIX_CHROMIUM or null) == browserTools.chromiumExecutable;
    in {
      checks.hitl-browser-automation-packages = pkgs.runCommand "hitl-browser-automation-packages-check" { } ''
        set -euo pipefail

        ${lib.optionalString (hasPackage hitl.hitlBrowserHub defaultPackages || hasPackage hitl.hitlBrowserHub defaultDevenvPackages) ''
          echo "hitl-browser-hub should not be installed by default" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage pkgs.tigervnc defaultPackages || hasPackage pkgs.tigervnc defaultDevenvPackages) ''
          echo "tigervnc should not be installed by default" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage hitl.hitlBrowserHub hitlPackages) || !(hasPackage hitl.hitlBrowserHub hitlDevenvPackages)) ''
          echo "hitl-browser-hub should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage browserTools.agentBrowserPackage hitlPackages) || !(hasPackage browserTools.agentBrowserPackage hitlDevenvPackages)) ''
          echo "agent-browser should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage browserTools.vhsPackage hitlPackages || hasPackage browserTools.vhsPackage hitlDevenvPackages) ''
          echo "vhs should not be installed by hitl browser automation alone" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage pkgs.nodejs hitlPackages) || !(hasPackage pkgs.nodejs hitlDevenvPackages)) ''
          echo "nodejs should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage pkgs.jq hitlPackages) || !(hasPackage pkgs.jq hitlDevenvPackages)) ''
          echo "jq should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage pkgs.python3 hitlPackages) || !(hasPackage pkgs.python3 hitlDevenvPackages)) ''
          echo "python3 should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage pkgs.curl hitlPackages) || !(hasPackage pkgs.curl hitlDevenvPackages)) ''
          echo "curl should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage pkgs.tigervnc hitlPackages) || !(hasPackage pkgs.tigervnc hitlDevenvPackages)) ''
          echo "tigervnc should be installed when toolnix.hitlBrowserAutomation.enable = true" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasBrowserEnv hitlEnv) || !(hasBrowserEnv hitlDevenvEnv)) ''
          echo "hitl browser automation env should point at toolnix pkgs.chromium" >&2
          exit 1
        ''}

        if [ ! -x ${lib.escapeShellArg hitl.skillCommand} ]; then
          echo "agent-skills input must contain executable hitl-browser-hub skill command" >&2
          exit 1
        fi
        ${hitl.hitlBrowserHub}/bin/hitl-browser-hub help >/dev/null

        touch "$out"
      '';
    };

    toolnix.features.hitlBrowserAutomation = {
      data = hitlBrowserAutomationData;

      homeManagerOptionModule = { lib, ... }: {
        options.toolnix.hitlBrowserAutomation.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable opt-in human-in-the-loop browser automation runtime support: skill-owned hub wrapper, agent-browser, Chromium env, Node, jq, Python, and VNC/display tools.";
        };
      };

      devenvOptionModule = { lib, ... }: {
        options.toolnix.hitlBrowserAutomation.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable opt-in human-in-the-loop browser automation runtime support in the project shell.";
        };
      };
    };
  };
}
