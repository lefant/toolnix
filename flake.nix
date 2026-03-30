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

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = import ./flake-parts;
    };
}
