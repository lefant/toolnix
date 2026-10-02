{ config, inputs, ... }:
let
  flakeConfig = config;
in {
  perSystem = { pkgs, ... }:
    let
      plugin = pkgs.runCommand "toolnix-antithesis-amp-plugin" {
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        python3 ${../../modules/shared/antithesis/render-amp-plugin.py} \
          ${inputs.agent-skills} "$out" ${inputs.agent-skills.rev or "unlocked"}
      '';
      home = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          flakeConfig.toolnix.profiles.homeManager.defaultModule
          {
            home.username = "exedev";
            home.homeDirectory = "/tmp/toolnix-check";
            home.stateVersion = "25.05";
          }
        ];
      };
      files = home.config.home.file;
    in {
      packages.antithesis-amp-plugin = plugin;
      checks.antithesis-amp-plugin-export = pkgs.runCommand "antithesis-amp-plugin-export-check" {
        nativeBuildInputs = [ pkgs.python3 pkgs.bash pkgs.coreutils pkgs.findutils ];
      } ''
        python3 ${../../scripts/tests/antithesis-amp-plugin.py} \
          ${inputs.agent-skills}/vendor/antithesishq ${plugin} \
          ${../../scripts/export-antithesis-amp-plugin.sh}
        touch "$out"
      '';
      checks.antithesis-agent-baseline = pkgs.runCommand "antithesis-agent-baseline-check" {} ''
        for tree in ${files.".agents/skills".source} ${files.".config/amp/skills".source}; do
          test ! -e "$tree/antithesis-research"
          test -e "$tree/agent-browser/SKILL.md"
          if readlink "$tree"/* | grep -q '/vendor/antithesishq/'; then
            echo "bare Antithesis skill leaked into Amp discovery" >&2
            exit 1
          fi
        done
        for tree in ${files.".claude/skills".source} ${files.".config/opencode/skills".source} \
          ${files.".pi/agent/skills".source} ${files.".codex/skills/antithesis".source}; do
          test -e "$tree/antithesis-research/SKILL.md"
          test -e "$tree/antithesis-mutation-testing/assets/mutation-testing/clean.sh"
          test "$(readlink "$tree"/* | grep -c '/vendor/antithesishq/')" -eq 14
        done
        touch "$out"
      '';
    };
}
