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
readonly ICON_RATE='󰖡'     # nf-md-speedometer

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
# Characters: ' ▏▎▍▌▋▊▉█' (9 levels per cell, 8 sub-steps)
# bar_width=10 cells → 80 discrete steps. No unfilled background.
progress_bar() {
  local -i percentage=${1:-0}
  local fill_color=${2:-$GREEN}
  local -i bar_width=10
  local blocks=(' ' '▏' '▎' '▍' '▌' '▋' '▊' '▉' '█')
  local -i total_units=$(( percentage * bar_width * 8 / 100 ))
  (( total_units > bar_width * 8 )) && total_units=$(( bar_width * 8 ))
  local -i filled_count=$(( total_units / 8 ))
  local -i partial_index=$(( total_units % 8 ))

  # Build filled portion
  local filled_string
  printf -v filled_string '%*s' "$filled_count" ''
  filled_string=${filled_string// /█}

  # Append partial block if needed
  if (( filled_count < bar_width && partial_index > 0 )); then
    filled_string+=${blocks[$partial_index]}
  fi

  # Pad with spaces to fill bar_width
  local -i used_cells=$(( filled_count + (partial_index > 0 ? 1 : 0) ))
  local -i pad_count=$(( bar_width - used_cells ))
  local pad_string
  printf -v pad_string '%*s' "$pad_count" ''

  printf '%s%s%s' "$fill_color" "$filled_string" "$pad_string"
}

# ─── Parse JSON (single jq call) ───
IFS=$'\t' read -r model working_directory used_percentage_raw five_hour_pct five_hour_resets seven_day_pct seven_day_resets < <(
  jq -r '[
    (.model.display_name // "Unknown"),
    (.cwd // "."),
    (.context_window.used_percentage // 0 | tostring),
    (.rate_limits.five_hour.used_percentage // "" | tostring),
    (.rate_limits.five_hour.resets_at // "" | tostring),
    (.rate_limits.seven_day.used_percentage // "" | tostring),
    (.rate_limits.seven_day.resets_at // "" | tostring)
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

# ─── LINE 4: Rate limits (5h / 7d) ───
format_resets_at() {
  local epoch=${1:-}
  [[ -z $epoch || $epoch == "null" ]] && return
  TZ="Asia/Tokyo" date -d "@${epoch}" "+%y-%m-%d %H:%M" 2>/dev/null || true
}

if [[ -n $five_hour_pct && $five_hour_pct != "null" ]]; then
  five_hour_int=$(printf '%.0f' "$five_hour_pct" 2>/dev/null || echo 0)
  five_color=$(color_for_percentage "$five_hour_int")
  five_bar=$(progress_bar "$five_hour_int" "$five_color")
  five_reset_str=$(format_resets_at "$five_hour_resets")
  five_reset_label=""
  [[ -n $five_reset_str ]] && five_reset_label=" ${GRAY}reset ${five_reset_str}${RESET}"
  printf '%s%s 5h quota%s  [%s%s] %s%3d%%%s%s\n' \
    "$FOREGROUND" "$ICON_RATE" "$RESET" \
    "$five_bar" "$RESET" \
    "$five_color" "$five_hour_int" "$RESET" \
    "$five_reset_label"
fi

if [[ -n $seven_day_pct && $seven_day_pct != "null" ]]; then
  seven_day_int=$(printf '%.0f' "$seven_day_pct" 2>/dev/null || echo 0)
  seven_color=$(color_for_percentage "$seven_day_int")
  seven_bar=$(progress_bar "$seven_day_int" "$seven_color")
  seven_reset_str=$(format_resets_at "$seven_day_resets")
  seven_reset_label=""
  [[ -n $seven_reset_str ]] && seven_reset_label=" ${GRAY}reset ${seven_reset_str}${RESET}"
  printf '%s%s 7d quota%s  [%s%s] %s%3d%%%s%s\n' \
    "$FOREGROUND" "$ICON_RATE" "$RESET" \
    "$seven_bar" "$RESET" \
    "$seven_color" "$seven_day_int" "$RESET" \
    "$seven_reset_label"
fi
