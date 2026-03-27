#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract context window information
current_usage=$(echo "$input" | jq -r '.context_window.current_usage // empty')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

if [ -n "$current_usage" ]; then
    # Calculate total tokens (input + cache creation + cache read)
    input_tokens=$(echo "$current_usage" | jq -r '.input_tokens // 0')
    cache_creation=$(echo "$current_usage" | jq -r '.cache_creation_input_tokens // 0')
    cache_read=$(echo "$current_usage" | jq -r '.cache_read_input_tokens // 0')
    total_tokens=$((input_tokens + cache_creation + cache_read))

    # Calculate percentage
    pct=$(awk "BEGIN {printf \"%.1f\", ($total_tokens * 100.0 / $context_size)}")
else
    total_tokens=0
    pct="0.0"
fi

# Get model and directory info
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "."')
cwd_short=$(basename "$cwd")

# Git repo@branch (optional)
repo_branch=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

    if [ -n "$remote_url" ]; then
        # Extract repo name from URL (e.g., "owner/repo" from git@github.com:owner/repo.git)
        repo_name=$(echo "$remote_url" | sed 's/\.git$//' | grep -oE '[^/:]+/[^/:]+$')
    else
        # Fallback to directory basename
        repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
    fi

    if [ -n "$branch" ]; then
        repo_branch="${repo_name}@${branch}"
    else
        repo_branch="${repo_name}"
    fi
fi

# Colors
CYAN='\033[36m'
RESET='\033[0m'

# Build status line
left=""
if [ -n "$repo_branch" ]; then
    left="${repo_branch} | "
fi
left="${left}${cwd}"

right="${CYAN}Ctx: ${pct}%${RESET} | ${CYAN}${total_tokens}${RESET} | ${model}"

echo -e "${left}  ${right}"
