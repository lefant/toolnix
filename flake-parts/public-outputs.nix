{ config, inputs, self, ... }:
let
  system = "x86_64-linux";
  homeManagerDefaultModule = config.toolnix.profiles.homeManager.defaultModule;
  homeManagerAgentsModule = config.toolnix.profiles.homeManager.agentsModule;
  devenvDefaultModule = config.toolnix.profiles.devenv.defaultModule;
  mkHome = hostName:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs { inherit system; };
      extraSpecialArgs = { inherit inputs; };
      modules = [
        homeManagerDefaultModule
        {
          home.username = "exedev";
          home.homeDirectory = "/home/exedev";
          home.stateVersion = "25.05";

          toolnix.hostName = hostName;
        }
      ];
    };
in {
  flake = {
    homeConfigurations = {
      lefant-toolnix = mkHome "lefant-toolnix";
    };

    homeManagerModules = let
      exportModule = module: args: {
        imports = [
          module
          ({ ... }: {
            _module.args.inputs =
              (args.inputs or {})
              // {
                toolnix = self;
                inherit (inputs) agent-skills claude-code-plugins compound-engineering-plugin llm-agents nixpkgs home-manager;
              };
          })
        ];
      };
    in {
      default = exportModule homeManagerDefaultModule;
      agents = exportModule homeManagerAgentsModule;
    };

    devenvSources = {
      inherit (inputs) agent-skills claude-code-plugins compound-engineering-plugin llm-agents nixpkgs home-manager;
    };

    devenvModules.default =
      args:
      devenvDefaultModule (args // {
        inputs =
          (args.inputs or {})
          // {
            toolnix = self;
            inherit (inputs) agent-skills claude-code-plugins compound-engineering-plugin llm-agents nixpkgs home-manager;
          };
      });
  };
}
