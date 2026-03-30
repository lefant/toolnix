{
  description = "Toolnix: shared Nix modules for dev environments and hosts";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    agent-skills = {
      url = "github:lefant/agent-skills";
      flake = false;
    };
    claude-code-plugins = {
      url = "github:lefant/claude-code-plugins";
      flake = false;
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, home-manager, nixpkgs, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = import ./flake-parts;

      flake =
        let
          system = "x86_64-linux";
          homeManagerDefaultModule = self.lib.toolnix.profiles.homeManager.defaultModule;
          mkHome = hostName:
            home-manager.lib.homeManagerConfiguration {
              pkgs = import nixpkgs { inherit system; };
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
          homeConfigurations = {
            lefant-toolnix = mkHome "lefant-toolnix";
          };

          homeManagerModules.default = homeManagerDefaultModule;

          devenvSources = {
            inherit (inputs) agent-skills claude-code-plugins llm-agents nixpkgs home-manager;
          };

          devenvModules.default =
            args:
            self.lib.toolnix.profiles.devenv.defaultModule (args // {
              inputs =
                (args.inputs or {})
                // {
                  toolnix = self;
                  inherit (inputs) agent-skills claude-code-plugins llm-agents nixpkgs home-manager;
                };
            });
        };
    };
}
