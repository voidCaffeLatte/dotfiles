#!/bin/sh

input=$(cat)
title=$(echo "$input" | jq -r '.title // "Claude Code"')
timestamp=$(date +"%Y-%m-%d %H:%M:%S %z")
message=$(echo "$input" | jq -r '.message // "Needs your attention"')
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show(('@ $timestamp' + [char]10 + '$message'), '$title')" >/dev/null 2>&1 &
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"@ $timestamp\n$message\" with title \"$title\"" 2>/dev/null
# TODO: Add Linux (non-WSL) support using notify-send or similar
fi
