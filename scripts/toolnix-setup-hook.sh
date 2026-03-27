#!/bin/bash
# toolnix-setup-hook.sh - Idempotent environment initialization
# Runs as Docker entrypoint or host-native devenv enterShell.
#
# Portable paths:
#   Docker:      defaults to /opt/... (set by Dockerfile COPY)
#   Host-native: set TOOLNIX_SOURCE_DIR, SKILLS_SOURCE_DIR, CE_PLUGIN_DIR
#
# Modes:
#   Default:         run init + exec "$@" (Docker entrypoint)
#   TOOLNIX_SEED_ONLY=1: run init only, skip exec (devenv enterShell)

set -e

TOOLNIX_SOURCE_DIR="${TOOLNIX_SOURCE_DIR:-/opt/toolnix}"
AGENTS_DIR="${TOOLNIX_SOURCE_DIR}/agents"
SKILLS_SOURCE="${SKILLS_SOURCE_DIR:-/opt/lefant-agent-skills}"
CE_PLUGIN_DIR="${CE_PLUGIN_DIR:-/opt/compound-engineering-plugin}"

log() {
    echo "[toolnix-setup] $*"
}

ensure_managed_link() {
    local target="$1"
    local source="$2"

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ] && [ "$(readlink -f "$target" 2>/dev/null)" = "$(readlink -f "$source" 2>/dev/null)" ]; then
        return
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        local backup=""
        if [ -f "$target" ] && [ -f "$source" ] && cmp -s "$target" "$source"; then
            rm -f "$target"
        else
            backup="${target}.pre-managed-$(date -u +%Y%m%d%H%M%S)"
            mv "$target" "$backup"
            log "Backed up existing file before adopting managed link: $backup"
        fi
    fi

    ln -s "$source" "$target"
    log "Linked managed config: $target -> $source"
}

# -----------------------------------------------------------------------------
# Check bind-mounted directories are writable
# Docker creates missing host dirs as root:root; detect and fail early
# -----------------------------------------------------------------------------
check_mount_writability() {
    local dirs=(
        "$HOME/.claude"
        "$HOME/.codex"
        "$HOME/.local/share/opencode"
        "$HOME/.amp"
        "$HOME/.openclaw"
        "$HOME/.pi/agent"
    )
    local failed=0
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ] && [ ! -w "$dir" ]; then
            log "ERROR: $dir is not writable (likely created by Docker as root)"
            failed=1
        fi
    done
    if [ "$failed" -eq 1 ]; then
        log ""
        log "Fix: use the managed toolnix/dev shell path instead of raw docker startup"
        log "  or: manually create the config dirs before starting the container"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Initialize Claude Code configuration
# -----------------------------------------------------------------------------
init_claude() {
    local claude_dir="$HOME/.claude"
    local seed_only="${TOOLNIX_SEED_ONLY:-}"
    local managed_links="${TOOLNIX_USE_MANAGED_CONFIG_LINKS:-}"

    # Create directory if needed
    mkdir -p "$claude_dir"

    if [ -n "$managed_links" ]; then
        ensure_managed_link "$claude_dir/settings.json" "$AGENTS_DIR/claude/templates/settings.json"
    elif [ ! -f "$claude_dir/settings.json" ]; then
        log "Initializing ~/.claude/settings.json"
        cp "$AGENTS_DIR/claude/templates/settings.json" "$claude_dir/settings.json"
    fi

    # Copy .claude.json to home if not exists
    if [ ! -f "$HOME/.claude.json" ]; then
        log "Initializing ~/.claude.json"
        cp "$AGENTS_DIR/claude/templates/dot-claude.json" "$HOME/.claude.json"
    fi

    # In host-native seed-only mode, leave plugin installation to explicit
    # provision-time setup rather than re-running it on every shell entry.
    if [ -n "$seed_only" ]; then
        return
    fi

    # Initialize plugins — uses PLUGINS_SOURCE_DIR (host) or /opt (Docker)
    local plugins_dir="${PLUGINS_SOURCE_DIR:-/opt/lefant-claude-code-plugins}"
    if [ -d "$plugins_dir" ]; then
        if [ ! -d "$claude_dir/plugins/marketplaces/lefant-claude-code-plugins" ] || \
           [ "$(readlink -f "$claude_dir/plugins/marketplaces/lefant-claude-code-plugins" 2>/dev/null)" != "$plugins_dir" ]; then
            log "Initializing Claude plugins..."
            claude plugin marketplace add "$plugins_dir" 2>/dev/null || true

            claude plugin install lefant@lefant-claude-code-plugins 2>/dev/null || true
            claude plugin install ntfy@lefant-claude-code-plugins 2>/dev/null || true
            claude plugin install rpi@lefant-claude-code-plugins 2>/dev/null || true
        fi
    fi

    # Install compound engineering plugin (EveryInc)
    if [ -d "$CE_PLUGIN_DIR" ]; then
        if [ ! -d "$claude_dir/plugins/marketplaces/compound-engineering-plugin" ] || \
           [ "$(readlink -f "$claude_dir/plugins/marketplaces/compound-engineering-plugin" 2>/dev/null)" != "$CE_PLUGIN_DIR" ]; then
            log "Initializing compound engineering plugin..."
            claude plugin marketplace add "$CE_PLUGIN_DIR" 2>/dev/null || true
            claude plugin install compound-engineering@compound-engineering-plugin 2>/dev/null || true
        fi
    fi
}

# -----------------------------------------------------------------------------
# Initialize Codex configuration
# -----------------------------------------------------------------------------
init_codex() {
    local codex_dir="$HOME/.codex"
    local managed_links="${TOOLNIX_USE_MANAGED_CONFIG_LINKS:-}"
    mkdir -p "$codex_dir/skills"

    if [ -n "$managed_links" ] && [ -f "$AGENTS_DIR/codex/templates/config.toml" ]; then
        ensure_managed_link "$codex_dir/config.toml" "$AGENTS_DIR/codex/templates/config.toml"
    elif [ ! -f "$codex_dir/config.toml" ] && [ -f "$AGENTS_DIR/codex/templates/config.toml" ]; then
        log "Initializing ~/.codex/config.toml"
        cp "$AGENTS_DIR/codex/templates/config.toml" "$codex_dir/config.toml"
    fi
}

# -----------------------------------------------------------------------------
# Initialize OpenCode configuration
# -----------------------------------------------------------------------------
init_opencode() {
    local opencode_config="$HOME/.config/opencode"
    local opencode_data="$HOME/.local/share/opencode"
    local managed_links="${TOOLNIX_USE_MANAGED_CONFIG_LINKS:-}"

    mkdir -p "$opencode_config/skills" "$opencode_data"

    if [ -n "$managed_links" ]; then
        ensure_managed_link "$opencode_config/opencode.json" "$AGENTS_DIR/opencode/templates/opencode.json"
    elif [ ! -f "$opencode_config/opencode.json" ]; then
        log "Initializing ~/.config/opencode/opencode.json"
        cp "$AGENTS_DIR/opencode/templates/opencode.json" "$opencode_config/opencode.json"
    fi
}

# -----------------------------------------------------------------------------
# Initialize Amp configuration
# -----------------------------------------------------------------------------
init_amp() {
    local amp_dir="$HOME/.amp"
    local amp_config="$HOME/.config/amp"
    local managed_links="${TOOLNIX_USE_MANAGED_CONFIG_LINKS:-}"

    mkdir -p "$amp_dir" "$amp_config"

    if [ -n "$managed_links" ] && [ -f "$AGENTS_DIR/amp/templates/settings.json" ]; then
        ensure_managed_link "$amp_config/settings.json" "$AGENTS_DIR/amp/templates/settings.json"
    elif [ ! -f "$amp_config/settings.json" ] && [ -f "$AGENTS_DIR/amp/templates/settings.json" ]; then
        log "Initializing ~/.config/amp/settings.json"
        cp "$AGENTS_DIR/amp/templates/settings.json" "$amp_config/settings.json"
    fi
}

# -----------------------------------------------------------------------------
# Initialize OpenClaw configuration
# -----------------------------------------------------------------------------
init_openclaw() {
    local openclaw_dir="$HOME/.openclaw"
    local managed_links="${TOOLNIX_USE_MANAGED_CONFIG_LINKS:-}"

    mkdir -p "$openclaw_dir"

    if [ -n "$managed_links" ] && [ -f "$AGENTS_DIR/openclaw/templates/openclaw.json" ]; then
        ensure_managed_link "$openclaw_dir/openclaw.json" "$AGENTS_DIR/openclaw/templates/openclaw.json"
    elif [ ! -f "$openclaw_dir/openclaw.json" ] && [ -f "$AGENTS_DIR/openclaw/templates/openclaw.json" ]; then
        log "Initializing ~/.openclaw/openclaw.json"
        cp "$AGENTS_DIR/openclaw/templates/openclaw.json" "$openclaw_dir/openclaw.json"
    fi
}

# -----------------------------------------------------------------------------
# Initialize Pi Coding Agent configuration
# -----------------------------------------------------------------------------
init_piagent() {
    local pi_dir="$HOME/.pi/agent"
    local managed_links="${TOOLNIX_USE_MANAGED_CONFIG_LINKS:-}"

    mkdir -p "$pi_dir"

    if [ -n "$managed_links" ] && [ -f "$AGENTS_DIR/pi-coding-agent/templates/settings.json" ]; then
        ensure_managed_link "$pi_dir/settings.json" "$AGENTS_DIR/pi-coding-agent/templates/settings.json"
    elif [ ! -f "$pi_dir/settings.json" ] && [ -f "$AGENTS_DIR/pi-coding-agent/templates/settings.json" ]; then
        log "Initializing ~/.pi/agent/settings.json"
        cp "$AGENTS_DIR/pi-coding-agent/templates/settings.json" "$pi_dir/settings.json"
    fi

    if [ -n "$managed_links" ] && [ -f "$AGENTS_DIR/pi-coding-agent/templates/keybindings.json" ]; then
        ensure_managed_link "$pi_dir/keybindings.json" "$AGENTS_DIR/pi-coding-agent/templates/keybindings.json"
    elif [ ! -f "$pi_dir/keybindings.json" ] && [ -f "$AGENTS_DIR/pi-coding-agent/templates/keybindings.json" ]; then
        log "Initializing ~/.pi/agent/keybindings.json"
        cp "$AGENTS_DIR/pi-coding-agent/templates/keybindings.json" "$pi_dir/keybindings.json"
    fi
}

# -----------------------------------------------------------------------------
# Initialize shared skills (symlinks from /opt/lefant-agent-skills)
# -----------------------------------------------------------------------------
init_skills() {
    local agents_skills="$HOME/.agents/skills"
    local claude_skills="$HOME/.claude/skills"
    local codex_skills="$HOME/.codex/skills"
    local opencode_skills="$HOME/.config/opencode/skills"
    local amp_skills="$HOME/.config/amp/skills"
    local openclaw_skills="$HOME/.openclaw/skills"
    local piagent_skills="$HOME/.pi/agent/skills"
    local managed_tree="${TOOLNIX_MANAGED_SKILL_TREE:-}"
    local managed_manifest="${TOOLNIX_MANAGED_SKILL_MANIFEST:-}"
    local ce_skills="$CE_PLUGIN_DIR/plugins/compound-engineering/skills"

    if [ -z "$managed_tree" ] && [ -n "$managed_manifest" ] && [ -f "$managed_manifest" ]; then
        managed_tree="$(awk -F '\t' '$1 == "__TREE__" { print $2; exit }' "$managed_manifest")"
    fi

    ensure_agents_skills_path() {
        local target_path="$1"

        mkdir -p "$(dirname "$agents_skills")"

        if [ -L "$agents_skills" ] && [ "$(readlink -f "$agents_skills" 2>/dev/null)" = "$target_path" ]; then
            return
        fi

        if [ -d "$agents_skills" ] && [ ! -L "$agents_skills" ]; then
            rm -f "$agents_skills"/*
            rmdir "$agents_skills"
        elif [ -L "$agents_skills" ] || [ -e "$agents_skills" ]; then
            rm -f "$agents_skills"
        fi

        ln -s "$target_path" "$agents_skills"
    }

    ensure_agent_skills_symlink() {
        local target_dir="$1"
        mkdir -p "$(dirname "$target_dir")"

        if [ -L "$target_dir" ] && [ "$(readlink -f "$target_dir" 2>/dev/null)" = "$agents_skills" ]; then
            return
        fi

        if [ -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
            local can_replace=1
            local entry
            for entry in "$target_dir"/*; do
                [ -e "$entry" ] || continue
                if [ ! -L "$entry" ]; then
                    can_replace=0
                    break
                fi
                local raw_target resolved_target expected_target
                raw_target="$(readlink "$entry" 2>/dev/null || true)"
                resolved_target="$(readlink -f "$entry" 2>/dev/null || true)"
                expected_target="$(readlink -f "$agents_skills/$(basename "$entry")" 2>/dev/null || true)"
                case "$raw_target" in
                    "$agents_skills"/*) ;;
                    *)
                        if [ -z "$expected_target" ] || [ "$resolved_target" != "$expected_target" ]; then
                            can_replace=0
                            break
                        fi
                        ;;
                esac
            done

            if [ "$can_replace" -eq 1 ]; then
                rm -f "$target_dir"/*
                rmdir "$target_dir"
            fi
        fi

        if [ ! -e "$target_dir" ]; then
            ln -s "$agents_skills" "$target_dir"
        fi
    }

    # In the common host-native case, standard skills are now a single Nix-built
    # tree. Only fall back to a writable overlay directory if runtime extras must
    # be merged in later.
    if [ -n "$managed_tree" ] && [ -d "$managed_tree" ] && [ ! -d "$ce_skills" ]; then
        ensure_agents_skills_path "$managed_tree"
    else
        mkdir -p "$agents_skills"

        if [ -n "$managed_tree" ] && [ -d "$managed_tree" ]; then
            for skill in "$managed_tree"/*; do
                [ -e "$skill" ] || continue
                skill_name=$(basename "$skill")
                target="$agents_skills/$skill_name"
                if [ ! -e "$target" ]; then
                    ln -s "$skill" "$target"
                    log "Linked managed skill: $skill_name"
                fi
            done
        elif [ -n "$managed_manifest" ] && [ -f "$managed_manifest" ]; then
            while IFS=$'\t' read -r skill_name skill_path; do
                [ -n "$skill_name" ] || continue
                [ "$skill_name" = "__TREE__" ] && continue
                target="$agents_skills/$skill_name"
                if [ ! -e "$target" ]; then
                    ln -s "$skill_path" "$target"
                    log "Linked managed skill: $skill_name"
                fi
            done < "$managed_manifest"
        elif [ -d "$SKILLS_SOURCE" ]; then
            # Symlink all skills from lefant-agent-skills to ~/.agents/skills/
            # Link lefant/ skills
            if [ -d "$SKILLS_SOURCE/lefant" ]; then
                for skill in "$SKILLS_SOURCE/lefant"/*; do
                    if [ -d "$skill" ]; then
                        skill_name=$(basename "$skill")
                        target="$agents_skills/$skill_name"
                        if [ ! -e "$target" ]; then
                            ln -s "$skill" "$target"
                            log "Linked skill: $skill_name"
                        fi
                    fi
                done
            fi

            # Link vendor/ skills (flattened - vendor/org/skill -> ~/.agents/skills/skill)
            if [ -d "$SKILLS_SOURCE/vendor" ]; then
                for org in "$SKILLS_SOURCE/vendor"/*; do
                    if [ -d "$org" ]; then
                        for skill in "$org"/*; do
                            if [ -d "$skill" ]; then
                                skill_name=$(basename "$skill")
                                target="$agents_skills/$skill_name"
                                if [ ! -e "$target" ]; then
                                    ln -s "$skill" "$target"
                                    log "Linked skill: $skill_name (from $(basename "$org"))"
                                fi
                            fi
                        done
                    fi
                done
            fi
        fi

        # Link compound engineering skills (plugins/compound-engineering/skills/)
        if [ -d "$ce_skills" ]; then
            for skill in "$ce_skills"/*; do
                if [ -d "$skill" ]; then
                    skill_name=$(basename "$skill")
                    target="$agents_skills/$skill_name"
                    if [ ! -e "$target" ]; then
                        ln -s "$skill" "$target"
                        log "Linked skill: $skill_name (from compound-engineering)"
                    fi
                fi
            done
        fi
    fi

    # For agents without extra reserved entries in their skills directory,
    # a single directory symlink avoids repeated per-skill fanout.
    for agent_skills in "$claude_skills" "$opencode_skills" "$amp_skills" "$openclaw_skills" "$piagent_skills"; do
        ensure_agent_skills_symlink "$agent_skills"
    done

    # Codex keeps internal bundled skills under ~/.codex/skills/.system.
    # Shared user skills now live canonically in ~/.agents/skills, so avoid
    # populating custom fanout inside ~/.codex/skills.
    mkdir -p "$codex_skills"

    for skill in "$codex_skills"/*; do
        if [ -L "$skill" ] && [ ! -e "$skill" ]; then
            rm -f "$skill"
        fi
        if [ -L "$skill" ]; then
            raw_target="$(readlink "$skill" 2>/dev/null || true)"
            resolved_target="$(readlink -f "$skill" 2>/dev/null || true)"
            case "$raw_target" in
                "$agents_skills"/*)
                    rm -f "$skill"
                    continue
                    ;;
            esac
            if [ -n "$resolved_target" ] && [ "$resolved_target" != "$skill" ]; then
                case "$resolved_target" in
                    "$agents_skills"/*)
                        rm -f "$skill"
                        ;;
                esac
            fi
        fi
    done

    log "Skills initialization complete"
}

# -----------------------------------------------------------------------------
# Experimental: install converted CE agents/commands for Codex and OpenCode
# These are generated during Docker build by the CE conversion CLI.
# -----------------------------------------------------------------------------
init_ce_converted() {
    local ce_converted="$CE_PLUGIN_DIR/converted"

    # Codex: converted agents/commands as prompts and skills
    if [ -d "$ce_converted/codex" ]; then
        local codex_dir="$HOME/.codex"
        mkdir -p "$codex_dir"
        # Copy prompts (converted commands)
        if [ -d "$ce_converted/codex/prompts" ]; then
            mkdir -p "$codex_dir/prompts"
            for f in "$ce_converted/codex/prompts"/*; do
                [ -f "$f" ] || continue
                fname=$(basename "$f")
                if [ ! -e "$codex_dir/prompts/$fname" ]; then
                    cp "$f" "$codex_dir/prompts/$fname"
                    log "Installed CE prompt for Codex: $fname"
                fi
            done
        fi
        log "Codex CE conversion installed"
    fi

    # OpenCode: converted agents/plugins
    if [ -d "$ce_converted/opencode" ]; then
        local opencode_config="$HOME/.config/opencode"
        mkdir -p "$opencode_config"
        # Copy agents
        if [ -d "$ce_converted/opencode/agents" ]; then
            mkdir -p "$opencode_config/agents"
            for f in "$ce_converted/opencode/agents"/*; do
                [ -f "$f" ] || continue
                fname=$(basename "$f")
                if [ ! -e "$opencode_config/agents/$fname" ]; then
                    cp "$f" "$opencode_config/agents/$fname"
                    log "Installed CE agent for OpenCode: $fname"
                fi
            done
        fi
        # Copy plugins
        if [ -d "$ce_converted/opencode/plugins" ]; then
            mkdir -p "$opencode_config/plugins"
            for f in "$ce_converted/opencode/plugins"/*; do
                [ -f "$f" ] || continue
                fname=$(basename "$f")
                if [ ! -e "$opencode_config/plugins/$fname" ]; then
                    cp "$f" "$opencode_config/plugins/$fname"
                    log "Installed CE plugin for OpenCode: $fname"
                fi
            done
        fi
        log "OpenCode CE conversion installed"
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    log "Starting toolnix initialization..."

    # Skip Docker-specific mount check in host-native mode
    if [ -z "${TOOLNIX_SEED_ONLY:-}" ]; then
        check_mount_writability
    fi

    init_claude
    init_codex
    init_opencode
    init_amp
    init_openclaw
    init_piagent
    init_skills
    init_ce_converted

    log "Initialization complete."
}

# Run initialization
main

# In seed-only mode (devenv enterShell), skip exec
if [ -n "${TOOLNIX_SEED_ONLY:-}" ]; then
    exit 0
fi

# Execute the actual command (Docker entrypoint mode)
exec "$@"
