{
  description = "Toolnix: shared Nix modules for dev environments and hosts";

  inputs = {
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

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      mkHome = hostName:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./modules/home-manager/toolnix-host.nix
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

      homeManagerModules.default = import ./modules/home-manager/toolnix-host.nix;

      devenvSources = {
        inherit (inputs) agent-skills claude-code-plugins llm-agents nixpkgs home-manager;
      };

      devenvModules.default =
        args:
        import ./modules/devenv/default.nix (args // {
          inputs =
            (args.inputs or {})
            // {
              toolnix = self;
              inherit (inputs) agent-skills claude-code-plugins llm-agents nixpkgs home-manager;
            };
        });
    };
}
