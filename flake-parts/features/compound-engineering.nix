{ config, inputs, ... }:
let
  flakeConfig = config;
  compoundEngineeringData = import ../../modules/shared/compound-engineering.nix;
in {
  config = {
    perSystem =
    { pkgs, system, ... }:
    let
      lib = pkgs.lib;
      compound = compoundEngineeringData { inherit pkgs lib inputs; };
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
      defaultHome = mkHome { };
      toolsOptOut = mkHome {
        toolnix.compoundEngineering.tools.enable = false;
      };
      skillsOptOut = mkHome {
        toolnix.compoundEngineering.skills.enable = false;
      };
      optOutFiles = skillsOptOut.config.home.file;
      optOutHasCodexSkills = builtins.hasAttr ".codex/skills/compound-engineering" optOutFiles;
      defaultPackages = defaultHome.config.home.packages;
      toolsOptOutPackages = toolsOptOut.config.home.packages;
      hasPackage = pkg: packages: lib.any (candidate: candidate == pkg) packages;
    in {
      checks.compound-engineering-assets = pkgs.runCommand "compound-engineering-assets-check" {
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        set -euo pipefail

        test -f ${compound.managedAmpSkillTree}/UPSTREAM_LICENSE
        test "$(cat ${compound.managedAmpSkillTree}/UPSTREAM_REVISION)" = ${lib.escapeShellArg compound.compoundRevision}
        test -e ${compound.managedAmpSkillTree}/ce-code-review/SKILL.md
        test -e ${compound.managedAmpSkillTree}/lfg/SKILL.md
        test "$(find ${compound.managedAmpSkillTree} -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 33
        test -e ${compound.managedOpenCodeSkillTree}/ce-code-review/SKILL.md
        test ! -e ${compound.managedOpenCodeSkillTree}/ce-update
        test -e ${compound.managedCodexSkillTree}/ce-code-review/SKILL.md
        test ! -e ${compound.managedCodexSkillTree}/ce-update

        OUT=${compound.managedCodexAgentTree} python3 - <<'PY'
import os
import pathlib
import tomllib
agent_dir = pathlib.Path(os.environ['OUT'])
agent_files = sorted(agent_dir.glob('*.toml'))
if not agent_files:
    raise SystemExit(f'no Codex agent TOML files rendered under {agent_dir}')
for path in agent_files:
    tomllib.loads(path.read_text(encoding='utf-8'))
PY

        touch "$out"
      '';

      checks.compound-engineering-amp-export = pkgs.runCommand "compound-engineering-amp-export-check" {
        nativeBuildInputs = [ pkgs.bash pkgs.coreutils pkgs.python3 ];
      } ''
        set -euo pipefail

        destination="$TMPDIR/global-skills"
        mkdir -p "$destination/unrelated-skill"
        cat >"$destination/unrelated-skill/SKILL.md" <<'EOF'
---
name: unrelated-skill
description: Remains untouched by the Compound Engineering exporter.
---
EOF

        ${pkgs.bash}/bin/bash ${../../scripts/export-compound-engineering-amp-skills.sh} \
          --source ${compound.managedAmpSkillTree} \
          "$destination"

        test -e "$destination/unrelated-skill/SKILL.md"
        test -e "$destination/ce-code-review/SKILL.md"
        test -e "$destination/ce-code-review/LICENSE"
        test -x "$destination/ce-babysit-pr/scripts/pr-snapshot"
        test -e "$destination/lfg/SKILL.md"

        python3 - "$destination/compound-engineering.lock.json" <<'PY'
import json
import pathlib
import sys

manifest = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["schemaVersion"] == 1
assert manifest["source"]["repository"] == "https://github.com/EveryInc/compound-engineering-plugin"
assert len(manifest["skills"]) == 33
assert "ce-code-review" in manifest["skills"]
assert "lfg" in manifest["skills"]
PY

        mkdir -p "$destination/retired-skill"
        python3 - "$destination/compound-engineering.lock.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["skills"].append("retired-skill")
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

        ${pkgs.bash}/bin/bash ${../../scripts/export-compound-engineering-amp-skills.sh} \
          --source ${compound.managedAmpSkillTree} \
          "$destination"
        test ! -e "$destination/retired-skill"
        test -e "$destination/unrelated-skill/SKILL.md"

        collision="$TMPDIR/collision"
        mkdir -p "$collision/ce-code-review"
        printf 'unmanaged\n' >"$collision/ce-code-review/marker"
        if ${pkgs.bash}/bin/bash ${../../scripts/export-compound-engineering-amp-skills.sh} \
          --source ${compound.managedAmpSkillTree} \
          "$collision"; then
          echo "exporter should reject an unmanaged skill-name collision" >&2
          exit 1
        fi
        test -e "$collision/ce-code-review/marker"
        test ! -e "$collision/compound-engineering.lock.json"

        touch "$out"
      '';

      checks.compound-engineering-amp-plugin-export = pkgs.runCommand "compound-engineering-amp-plugin-export-check" {
        nativeBuildInputs = [ pkgs.bash pkgs.coreutils pkgs.gnugrep pkgs.python3 ];
      } ''
        set -euo pipefail

        plugin=${compound.managedAmpPlugin}
        test -f "$plugin/index.ts"
        test -f "$plugin/LICENSE"
        test -f "$plugin/compound-engineering.lock.json"
        test -f "$plugin/skills/plan/SKILL.md"
        test -f "$plugin/skills/work/SKILL.md"
        test -f "$plugin/skills/lfg/SKILL.md"
        test ! -e "$plugin/skills/ce-plan"
        test "$(find "$plugin/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 33
        test "$(find "$plugin" -type f | wc -l)" -le 200
        test "$(grep -c "await amp.registerSkill({ path: 'skills/" "$plugin/index.ts")" -eq 33
        grep -q "await amp.registerSkill({ path: 'skills/plan' })" "$plugin/index.ts"
        grep -q "await amp.registerSkill({ path: 'skills/work' })" "$plugin/index.ts"
        grep -q "await amp.registerSkill({ path: 'skills/compound' })" "$plugin/index.ts"
        if grep -Fq 'for (const skill of skills)' "$plugin/index.ts"; then
          echo "Amp plugin skill registrations must use paths that global indexing can resolve statically" >&2
          exit 1
        fi
        grep -q '^name: "plan"$' "$plugin/skills/plan/SKILL.md"
        grep -q 'prefer ce:brainstorm for exploratory framing' "$plugin/skills/plan/SKILL.md"
        grep -q 'This package is registered as `ce:plan`' "$plugin/skills/plan/SKILL.md"
        grep -q 'invoke the Amp bundled skill `ce:<name>` instead' "$plugin/skills/plan/SKILL.md"
        test -f "$plugin/skills/plan/AMP_REFERENCES.md"
        test ! -f "$plugin/skills/plan/references/agents/agent-native-planning-strategist.md"
        grep -q '^## `references/agents/agent-native-planning-strategist.md`$' "$plugin/skills/plan/AMP_REFERENCES.md"
        grep -q 'product_contract_source: ce-plan' "$plugin/skills/plan/AMP_REFERENCES.md"
        test -x "$plugin/skills/babysit-pr/scripts/pr-snapshot"

        python3 - "$plugin/compound-engineering.lock.json" <<'PY'
import json
import pathlib
import sys

manifest = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["schemaVersion"] == 1
assert manifest["pluginName"] == "ce"
assert manifest["source"]["repository"] == "https://github.com/EveryInc/compound-engineering-plugin"
assert len(manifest["skills"]) == 33
assert {"upstream": "ce-plan", "bundled": "plan"} in manifest["skills"]
assert {"upstream": "lfg", "bundled": "lfg"} in manifest["skills"]
PY

        destination="$TMPDIR/global-plugins"
        mkdir -p "$destination/unrelated-plugin"
        printf 'export default function () {}\n' >"$destination/unrelated-plugin/index.ts"
        ${pkgs.bash}/bin/bash ${../../scripts/export-compound-engineering-amp-plugin.sh} \
          --source "$plugin" \
          "$destination"
        test -f "$destination/unrelated-plugin/index.ts"
        test -f "$destination/ce/index.ts"
        test -f "$destination/ce/skills/plan/SKILL.md"
        test "$(find "$destination/ce/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 33

        ${pkgs.bash}/bin/bash ${../../scripts/export-compound-engineering-amp-plugin.sh} \
          --source "$plugin" \
          "$destination"
        test -f "$destination/unrelated-plugin/index.ts"

        collision="$TMPDIR/collision"
        mkdir -p "$collision/ce"
        printf 'unmanaged\n' >"$collision/ce/marker"
        if ${pkgs.bash}/bin/bash ${../../scripts/export-compound-engineering-amp-plugin.sh} \
          --source "$plugin" \
          "$collision"; then
          echo "exporter should reject an unmanaged plugin-name collision" >&2
          exit 1
        fi
        test -f "$collision/ce/marker"

        file_collision="$TMPDIR/file-collision"
        mkdir -p "$file_collision"
        printf 'unmanaged\n' >"$file_collision/ce.ts"
        if ${pkgs.bash}/bin/bash ${../../scripts/export-compound-engineering-amp-plugin.sh} \
          --source "$plugin" \
          "$file_collision"; then
          echo "exporter should reject a single-file plugin-name collision" >&2
          exit 1
        fi
        test -f "$file_collision/ce.ts"

        touch "$out"
      '';

      packages.compound-engineering-amp-plugin = compound.managedAmpPlugin;
      packages.compound-engineering-amp-skills = compound.managedAmpSkillTree;

      checks.compound-engineering-tools = pkgs.runCommand "compound-engineering-tools-check" { } ''
        set -euo pipefail

        ${lib.optionalString (!(hasPackage pkgs.ast-grep defaultPackages)) ''
          echo "ast-grep should be installed when Compound Engineering tools are enabled" >&2
          exit 1
        ''}
        ${lib.optionalString (!(hasPackage pkgs.silicon defaultPackages)) ''
          echo "silicon should be installed when Compound Engineering tools are enabled" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage pkgs.vhs defaultPackages) ''
          echo "vhs should not be installed by the default Compound Engineering tool bundle" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage pkgs.ast-grep toolsOptOutPackages) ''
          echo "ast-grep should not be installed when toolnix.compoundEngineering.tools.enable = false" >&2
          exit 1
        ''}
        ${lib.optionalString (hasPackage pkgs.silicon toolsOptOutPackages) ''
          echo "silicon should not be installed when toolnix.compoundEngineering.tools.enable = false" >&2
          exit 1
        ''}

        touch "$out"
      '';

      checks.compound-engineering-skills-opt-out = pkgs.runCommand "compound-engineering-skills-opt-out-check" { } ''
        set -euo pipefail

        test ! -e ${optOutFiles.".agents/skills".source}/ce-code-review
        test ! -e ${optOutFiles.".claude/skills".source}/ce-code-review
        test ! -e ${optOutFiles.".config/opencode/skills".source}/ce-code-review
        test ! -e ${optOutFiles.".config/amp/skills".source}/ce-code-review
        test ! -e ${optOutFiles.".pi/agent/skills".source}/ce-code-review
        ${lib.optionalString optOutHasCodexSkills ''
          echo "Codex Compound skills should not be linked when toolnix.compoundEngineering.skills.enable = false" >&2
          exit 1
        ''}

        test -e ${optOutFiles.".claude/agents".source}/security-sentinel.md
        test -e ${optOutFiles.".config/opencode/agents".source}/security-sentinel.md
        test -e ${optOutFiles.".codex/agents/compound-engineering".source}/security-sentinel.toml

        touch "$out"
      '';
    };

    toolnix.features.compoundEngineering = {
    data = compoundEngineeringData;

    homeManagerOptionModule = { lib, ... }: {
      options.toolnix.compoundEngineering = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable the EveryInc Compound Engineering integration by default for Home Manager hosts.";
        };

        skills.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Compound Engineering skills into the managed agent skill tree when Compound Engineering is enabled.";
        };

        tools.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install native helper tools preferred by Compound Engineering agents.";
        };

        opencode.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install OpenCode-specific Compound Engineering skills and agent assets when Compound Engineering is enabled.";
        };

        claude.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Claude Code-specific Compound Engineering skills and agent assets when Compound Engineering is enabled.";
        };

        codex.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Codex CLI-specific Compound Engineering skills, agents, and compatibility guidance when Compound Engineering is enabled.";
        };

        pi.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install Pi-specific Compound Engineering agent assets when Compound Engineering is enabled.";
        };

        pi.subagentExtension.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install the Pi subagent extension used by Compound Engineering agents.";
        };
      };
    };

    devenvOptionModule = { lib, ... }: {
      options.toolnix.compoundEngineering = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable the EveryInc Compound Engineering project-shell integration by default.";
        };

        tools.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install native helper tools preferred by Compound Engineering agents.";
        };
      };
    };
    };
  };
}
