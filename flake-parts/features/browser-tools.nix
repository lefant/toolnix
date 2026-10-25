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
      combinedHome = mkHome {
        toolnix.agentBrowser.enable = true;
        toolnix.browserTools.enable = true;
        toolnix.hitlBrowserAutomation.enable = true;
      };
      combinedDevenv = mkDevenv {
        toolnix.agentBrowser.enable = true;
        toolnix.browserTools.enable = true;
        toolnix.hitlBrowserAutomation.enable = true;
      };
      checked = assert browserTools.agentBrowser.packages == [ ];
        assert browserTools.browserTools.packages == [ ];
        assert agentBrowserPackages == defaultPackages;
        assert browserToolsPackages == defaultPackages;
        assert combinedHome.config.home.packages == defaultPackages;
        assert agentBrowserDevenvPackages == defaultDevenvPackages;
        assert browserToolsDevenvPackages == defaultDevenvPackages;
        assert combinedDevenv.config.packages == defaultDevenvPackages;
        assert lib.all (env: env == defaultHome.config.home.sessionVariables) [
          agentBrowserEnv browserToolsEnv combinedHome.config.home.sessionVariables
        ];
        assert lib.all (env: env == defaultDevenv.config.env) [
          agentBrowserDevenvEnv browserToolsDevenvEnv combinedDevenv.config.env
        ]; true;
    in {
      checks.browser-tools-packages = assert checked; pkgs.runCommand "browser-tools-packages-check" { } ''
        touch "$out"
      '';
    };

    toolnix.features.browserTools = {
      data = browserToolsData;

      homeManagerOptionModule = { lib, ... }: {
        options.toolnix.browserTools.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Reserved browser-tools opt-in; currently a no-op pending TLS remediation.";
        };
      };

      devenvOptionModule = { lib, ... }: {
        options.toolnix.browserTools.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Reserved browser-tools opt-in; currently a no-op pending TLS remediation.";
        };
      };
    };
  };
}
