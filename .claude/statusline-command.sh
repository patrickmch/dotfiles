#!/bin/sh
# Claude Code status line — styled after af-magic zsh theme
# Receives JSON via stdin with session context

input=$(cat)

# Core fields
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Git branch (skip lock to avoid blocking)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Build directory + branch segment (af-magic left side style)
if [ -n "$branch" ]; then
  dir_part="$short_cwd ($branch)"
else
  dir_part="$short_cwd"
fi

# User@host (af-magic right side style)
user_host="$(whoami)@$(hostname -s)"

# Context usage
if [ -n "$used_pct" ]; then
  ctx_int=$(printf "%.0f" "$used_pct")
  ctx_part="ctx:${ctx_int}%"
else
  ctx_part=""
fi

# Compose status line with ANSI colors
# Colors: cyan for dir/branch, magenta for model, dim for user@host, yellow for ctx
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
YELLOW='\033[0;33m'
RESET='\033[0m'

if [ -n "$ctx_part" ]; then
  printf "${CYAN}%s${RESET}  ${MAGENTA}%s${RESET}  ${YELLOW}%s${RESET}  ${DIM}%s${RESET}" \
    "$dir_part" "$model" "$ctx_part" "$user_host"
else
  printf "${CYAN}%s${RESET}  ${MAGENTA}%s${RESET}  ${DIM}%s${RESET}" \
    "$dir_part" "$model" "$user_host"
fi
