{ config, inputs, ... }:
let
  profiles = config.toolnix.profiles.homeManager;
in {
  perSystem = { pkgs, system, ... }:
    let
      lib = pkgs.lib;
      mkHome = module: extra:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs { inherit system; };
          extraSpecialArgs = { inherit inputs; };
          modules = [ module {
            home.username = "exedev";
            home.homeDirectory = "/home/exedev";
            home.stateVersion = "25.05";
          } extra ];
        };
      portable = (mkHome profiles.agentsModule {}).config;
      full = (mkHome profiles.defaultModule {}).config;
      disabled = (mkHome profiles.defaultModule { toolnix.enableAgentBaseline = false; }).config;
      files = portable.home.file;
      packageNames = map (p: p.pname or p.name or "") portable.home.packages;
      required = [ ".claude/settings.json" ".codex/config.toml" ".pi/agent/settings.json" ".config/amp/settings.json" ".config/opencode/opencode.json" ".agents/skills" ".claude/skills" ".pi/agent/skills" ];
      absent = [ ".zshrc" ".gitconfig" ".ssh/config" ".tmux.conf" ];
      assertCheck = condition: message: if condition then true else throw message;
      checked = builtins.deepSeq [
        (assertCheck (lib.all (name: builtins.hasAttr name files) required) "agent profile missing an agent file")
        (assertCheck (lib.all (name: !(builtins.hasAttr name files)) absent) "agent profile owns host files")
        (assertCheck (lib.all (name: lib.any (pkg: lib.hasInfix name pkg) packageNames) [ "claude" "codex" "pi" "amp" "opencode" ]) "agent profile missing a CLI")
        (assertCheck (!(builtins.hasAttr "seedClaudeRuntimeState" portable.home.activation)) "portable profile seeds VM runtime state")
        (assertCheck (builtins.hasAttr "seedClaudeRuntimeState" full.home.activation) "full profile lost runtime seed")
        (assertCheck (lib.hasInfix "enableAllProjectMcpServers" (builtins.readFile full.home.file.".claude/settings.json".source)) "full profile lost MCP policy")
        (assertCheck (!(lib.hasInfix "enableAllProjectMcpServers" (builtins.readFile files.".claude/settings.json".source))) "portable profile inherited MCP policy")
        (assertCheck (lib.hasInfix "trust_level" (builtins.readFile full.home.file.".codex/config.toml".source)) "full profile lost trust policy")
        (assertCheck (!(lib.hasInfix "trust_level" (builtins.readFile files.".codex/config.toml".source))) "portable profile inherited trust policy")
        (assertCheck (!(builtins.hasAttr ".agents/skills" disabled.home.file)) "baseline disable flag lost effect")
        (assertCheck (builtins.hasAttr ".claude/settings.json" disabled.home.file) "unconditional settings became gated")
      ] true;
    in {
      checks.agent-profile = assert checked; pkgs.runCommand "agent-profile-check" {} ''touch "$out"'';
    };
}
