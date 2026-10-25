{ config, inputs, ... }:
let
  flakeConfig = config;
  hitlBrowserAutomationData = import ../../modules/shared/hitl-browser-automation.nix;
in {
  config = {
    perSystem =
    { pkgs, system, ... }:
    let
      lib = pkgs.lib;
      hitl = hitlBrowserAutomationData { inherit pkgs lib inputs; };
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
      checked = assert hitl.packages == [ ];
        assert hitlPackages == defaultPackages;
        assert hitlDevenvPackages == defaultDevenvPackages;
        assert hitlEnv == defaultHome.config.home.sessionVariables;
        assert hitlDevenvEnv == defaultDevenv.config.env;
        true;
    in {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      hitl-browser-automation-packages = assert checked; pkgs.runCommand "hitl-browser-automation-packages-check" { } ''
        touch "$out"
      '';
      };
    };

    toolnix.features.hitlBrowserAutomation = {
      data = hitlBrowserAutomationData;

      homeManagerOptionModule = { lib, ... }: {
        options.toolnix.hitlBrowserAutomation.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Reserved HITL browser opt-in; currently a no-op pending TLS remediation.";
        };
      };

      devenvOptionModule = { lib, ... }: {
        options.toolnix.hitlBrowserAutomation.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Reserved HITL browser opt-in; currently a no-op pending TLS remediation.";
        };
      };
    };
  };
}
