#!/usr/bin/env bash
set -euo pipefail

readonly input=$(cat)

# ─── ANSI 24-bit true color ───
# Color palette inspired by Gruvbox Dark (https://github.com/morhetz/gruvbox), MIT License.
hex_color() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }

readonly GREEN=$(hex_color b8bb26)       # gruvbox bright green
readonly YELLOW=$(hex_color fabd2f)      # gruvbox bright yellow
readonly RED=$(hex_color fb4934)         # gruvbox bright red
readonly BLUE=$(hex_color 83a598)        # gruvbox bright blue
readonly ORANGE=$(hex_color fe8019)      # gruvbox bright orange
readonly PURPLE=$(hex_color d3869b)      # gruvbox bright purple
readonly AQUA=$(hex_color 8ec07c)        # gruvbox bright aqua
readonly GRAY=$(hex_color 928374)        # gruvbox gray
readonly LIGHT_GRAY=$(hex_color a89984)  # gruvbox fg4
readonly FOREGROUND=$(hex_color ebdbb2)  # gruvbox fg1
readonly RESET=$'\033[0m'

# Nerd Font icons (nf-md only for consistency)
readonly ICON_MODEL='󰚩'    # nf-md-robot
readonly ICON_BRANCH='󰘬'   # nf-md-source_branch
readonly ICON_FOLDER='󰝰'   # nf-md-folder_open
readonly ICON_CLOCK='󰥔'    # nf-md-clock_outline
readonly ICON_CONTEXT='󰡫'  # nf-md-chart_box

readonly SEPARATOR="${GRAY}│${RESET}"

# ─── Helpers ───
color_for_percentage() {
  local -i percentage=${1:-0}
  if (( percentage <= 49 )); then
    printf '%s' "$GREEN"
  elif (( percentage <= 79 )); then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$RED"
  fi
}

# Block-shade progress bar using Unicode Block Elements
# Each cell = 10%. Filled cells use █, unfilled use ░ (gray).
# Partial cell shade by remainder (percent % 10): 0-2=none, 3-4=░, 5-6=▒, 7-8=▓, 9=█
progress_bar() {
  local -i percentage=${1:-0}
  local fill_color=${2:-$GREEN}
  local -i bar_width=10
  local -i filled_count=$(( percentage / 10 ))
  (( filled_count > bar_width )) && filled_count=$bar_width
  local -i remainder=$(( percentage % 10 ))

  # Determine partial block character
  local partial_block=""
  if (( filled_count < bar_width )); then
    if   (( remainder >= 9 )); then partial_block="█"
    elif (( remainder >= 7 )); then partial_block="▓"
    elif (( remainder >= 5 )); then partial_block="▒"
    elif (( remainder >= 3 )); then partial_block="░"
    fi
  fi

  # Build filled portion
  local filled_string
  printf -v filled_string '%*s' "$filled_count" ''
  filled_string=${filled_string// /█}
  [[ -n $partial_block ]] && filled_string+=$partial_block && (( filled_count++ ))

  # Build unfilled portion
  local -i unfilled_count=$(( bar_width - filled_count ))
  local unfilled_string
  printf -v unfilled_string '%*s' "$unfilled_count" ''
  unfilled_string=${unfilled_string// /░}

  printf '%s%s%s%s' "$fill_color" "$filled_string" "$GRAY" "$unfilled_string"
}

# ─── Parse JSON (single jq call) ───
IFS=$'\t' read -r model working_directory used_percentage_raw < <(
  jq -r '[
    (.model.display_name // "Unknown"),
    (.cwd // "."),
    (.context_window.used_percentage // 0 | tostring)
  ] | join("\t")' <<< "$input"
)

effort_level=$(jq -r '.effortLevel // "default"' "$HOME/.claude/settings.json" 2>/dev/null || echo "default")

used_percentage=$(printf '%.0f' "$used_percentage_raw" 2>/dev/null || echo 0)

# ─── Git info ───
git_options=(--no-optional-locks -C "$working_directory")
git_branch=$(git "${git_options[@]}" branch --show-current 2>/dev/null || true)
git_remote_branch=$(git "${git_options[@]}" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)

# ─── Capture timestamp immediately before output ───
current_timestamp=$(TZ="Asia/Tokyo" date "+%Y-%m-%d %H:%M:%S")
context_color=$(color_for_percentage "$used_percentage")
context_bar=$(progress_bar "$used_percentage" "$context_color")

# ─── LINE 1: Timestamp │ Model │ Branch ───
if ! git "${git_options[@]}" rev-parse --is-inside-work-tree &>/dev/null; then
  branch_display="${GRAY}— no git —"
elif [[ -n $git_branch ]]; then
  branch_display="$git_branch"
  [[ -n $git_remote_branch ]] && branch_display+=" ${LIGHT_GRAY}→ ${git_remote_branch}${AQUA}"
else
  branch_display="detached HEAD"
fi
printf '%s%s %s JST%s  %s  %s%s %s%s [%s]%s  %s  %s%s %s%s\n' \
  "$FOREGROUND" "$ICON_CLOCK" "$current_timestamp" "$RESET" \
  "$SEPARATOR" \
  "$ORANGE" "$ICON_MODEL" "$model" "$RESET" "$effort_level" "$RESET" \
  "$SEPARATOR" \
  "$AQUA" "$ICON_BRANCH" "$branch_display" "$RESET"

# ─── LINE 2: Folder ───
printf '%s%s %s%s\n' "$FOREGROUND" "$ICON_FOLDER" "$working_directory" "$RESET"

# ─── LINE 3: Context window ───
printf '%s%s context%s   [%s%s] %s%3d%%%s\n' \
  "$FOREGROUND" "$ICON_CONTEXT" "$RESET" \
  "$context_bar" "$RESET" \
  "$context_color" "$used_percentage" "$RESET"
