{ config, inputs, ... }:
let
  flakeConfig = config;
in {
  perSystem = { pkgs, ... }:
    let
      plugin = pkgs.runCommand "toolnix-matt-pocock-amp-plugin" {
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        python3 ${../../modules/shared/matt-pocock/render-amp-plugin.py} \
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
      packages.matt-pocock-amp-plugin = plugin;
      checks.matt-pocock-amp-plugin-export = pkgs.runCommand "matt-pocock-amp-plugin-export-check" {
        nativeBuildInputs = [ pkgs.python3 pkgs.bash pkgs.coreutils pkgs.findutils ];
      } ''
        python3 ${../../scripts/tests/matt-pocock-amp-plugin.py} \
          ${inputs.agent-skills}/vendor/mattpocock ${plugin} \
          ${../../scripts/export-matt-pocock-amp-plugin.sh}
        touch "$out"
      '';
      checks.matt-pocock-agent-baseline = pkgs.runCommand "matt-pocock-agent-baseline-check" {} ''
        for tree in ${files.".agents/skills".source} ${files.".config/amp/skills".source}; do
          test ! -e "$tree/grill-me"
          test ! -e "$tree/setup-matt-pocock-skills"
          test -e "$tree/handover/SKILL.md"
          if readlink "$tree"/* | grep -q '/vendor/mattpocock/'; then
            echo "bare MP skill leaked into Amp discovery" >&2
            exit 1
          fi
        done
        for tree in ${files.".claude/skills".source} ${files.".config/opencode/skills".source} \
          ${files.".pi/agent/skills".source} ${files.".codex/skills/matt-pocock".source}; do
          test -e "$tree/grill-me/SKILL.md"
          test -e "$tree/tdd/SKILL.md"
          test "$(readlink "$tree"/* | grep -c '/vendor/mattpocock/')" -eq 27
        done
        touch "$out"
      '';
    };
}
