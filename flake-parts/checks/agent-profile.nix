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
      retargeted = (mkHome profiles.agentsModule {
        home.file.".claude/settings.json".target = ".claude/custom-settings.json";
        home.file.".codex/config.toml".enable = false;
      }).config;
      files = portable.home.file;
      packageNames = map (p: p.pname or p.name or "") portable.home.packages;
      codex = inputs.llm-agents.packages.${system}.codex;
      portableCodex = lib.findFirst (p: (p.pname or "") == "codex") null portable.home.packages;
      required = [ ".claude/settings.json" ".pi/agent/settings.json" ".config/amp/settings.json" ".config/opencode/opencode.json" ".claude/skills" ".pi/agent/skills" ];
      absent = [ ".zshrc" ".gitconfig" ".ssh/config" ".tmux.conf" ".codex/config.toml" ".agents/skills" ];
      assertCheck = condition: message: if condition then true else throw message;
      checked = builtins.deepSeq [
        (assertCheck (lib.all (name: !files.${name}.force) required) "portable profile still forces managed agent links")
        (assertCheck (lib.all (name: full.home.file.${name}.force) required) "full profile lost forced links")
        (assertCheck full.home.file.".agents/skills".force "full profile lost shared skills")
        (assertCheck (builtins.hasAttr ".codex/skills/toolnix" files) "portable Codex lost baseline skills")
        (assertCheck (builtins.hasAttr "toolnixAdoptAgents" portable.home.activation) "portable profile missing adoption")
        (assertCheck (!(builtins.hasAttr "toolnixAdoptAgents" full.home.activation)) "full profile gained adoption")
        (assertCheck (lib.hasInfix ".claude/custom-settings.json" retargeted.home.activation.toolnixAdoptAgents.data) "adoption omitted retargeted file")
        (assertCheck (!(lib.hasInfix "'.codex/config.toml'" retargeted.home.activation.toolnixAdoptAgents.data)) "adoption included disabled file")
        (assertCheck (!(lib.hasInfix "'.claude/settings.json'" retargeted.home.activation.toolnixAdoptAgents.data)) "adoption included old target")
        (assertCheck (lib.all (name: builtins.hasAttr name files) required) "agent profile missing an agent file")
        (assertCheck (lib.all (name: !(builtins.hasAttr name files)) absent) "agent profile owns host files")
        (assertCheck (lib.all (name: lib.any (pkg: lib.hasInfix name pkg) packageNames) [ "claude" "codex" "pi" "amp" "opencode" ]) "agent profile missing a CLI")
        (assertCheck (!(builtins.hasAttr "seedClaudeRuntimeState" portable.home.activation)) "portable profile seeds VM runtime state")
        (assertCheck (builtins.hasAttr "seedClaudeRuntimeState" full.home.activation) "full profile lost runtime seed")
        (assertCheck (lib.hasInfix "enableAllProjectMcpServers" (builtins.readFile full.home.file.".claude/settings.json".source)) "full profile lost MCP policy")
        (assertCheck (!(lib.hasInfix "enableAllProjectMcpServers" (builtins.readFile files.".claude/settings.json".source))) "portable profile inherited MCP policy")
        (assertCheck (lib.hasInfix "trust_level" (builtins.readFile full.home.file.".codex/config.toml".source)) "full profile lost trust policy")
        (assertCheck (lib.elem codex full.home.packages) "full profile lost upstream Codex")
        (assertCheck (!(lib.elem codex portable.home.packages)) "portable profile still installs raw Codex")
        (assertCheck (portableCodex.version == codex.version) "portable Codex version diverged")
        (assertCheck (!(builtins.fromJSON (builtins.readFile files.".config/opencode/opencode.json".source) ? permission)) "portable profile inherited OpenCode blanket permissions")
        (assertCheck ((builtins.fromJSON (builtins.readFile full.home.file.".config/opencode/opencode.json".source)).permission."*" == "allow") "Linux OpenCode permissions changed")
        (assertCheck ((builtins.fromJSON (builtins.readFile files.".claude/settings.json".source)).model == "opus") "portable Claude model changed")
        (assertCheck (!(builtins.hasAttr ".agents/skills" disabled.home.file)) "baseline disable flag lost effect")
        (assertCheck (builtins.hasAttr ".claude/settings.json" disabled.home.file) "unconditional settings became gated")
      ] true;
      managedStore = pkgs.runCommand "test-home-manager-files" {} ''
        mkdir -p "$out/.claude"
        echo managed > "$out/.claude/settings.json"
      '';
    in {
      checks.agent-profile = assert checked; pkgs.runCommand "agent-profile-check" {
        nativeBuildInputs = [ pkgs.bash pkgs.coreutils pkgs.findutils pkgs.gnused ];
        TOOLNIX_TEST_MANAGED_STORE = managedStore;
        TOOLNIX_TEST_HELPER = ../../scripts/agent-adoption.sh;
      } ''
        bash ${../../scripts/tests/test-agent-adoption.sh}
        # Substitute only the delegate, then execute the actual generated wrapper.
        # This checks quoting and that user arguments follow declared defaults.
        printf '#!${pkgs.bash}/bin/bash\nprintf "%%s\\n" "$@"\n' > delegate
        chmod +x delegate
        sed "s|${codex}/bin/codex|$PWD/delegate|g" ${portableCodex}/bin/codex > wrapper
        bash wrapper -c 'model="session-model"' exec --help > actual
        cat > expected <<'EOF'
        -c
        model="gpt-6-astra"
        -c
        model_reasoning_effort="high"
        -c
        personality="pragmatic"
        -c
        model="session-model"
        exec
        --help
        EOF
        diff -u expected actual
        test -e ${files.".codex/skills/toolnix".source}/agent-browser/SKILL.md
        test -e ${files.".config/amp/skills".source}/using-exe-dev/SKILL.md
        test ! -e ${files.".config/amp/skills".source}/agent-browser
        test ! -e ${files.".config/amp/skills".source}/ce-plan
        touch "$out"
      '';
    };
}
