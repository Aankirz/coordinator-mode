#!/usr/bin/env bash
# Spawn a Claude builder session in a new, visible terminal window.
# Usage: spawn-builder.sh [--cwd DIR] [--model M] [--brief FILE | --prompt TEXT]
# Env:   BUILDER_TERMINAL  force a terminal (wezterm|ghostty|kitty|alacritty|iterm|terminal|gnome-terminal|konsole|xterm|tmux)
#        BUILDER_CLAUDE_ARGS  extra args passed through to `claude`
# Prints the session id on stdout so the coordinator can hand it to the owner.
set -euo pipefail

CWD="$PWD"; MODEL="opus"; PROMPT=""; DRY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) CWD="$2"; shift 2;;
    --model) MODEL="$2"; shift 2;;
    --brief) PROMPT="$(cat "$2")"; shift 2;;
    --prompt) PROMPT="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
[ -n "$PROMPT" ] || { echo "need --brief or --prompt" >&2; exit 2; }

SID="$(uuidgen | tr 'A-Z' 'a-z')"
SHELL_BIN="${SHELL:-/bin/bash}"

# The command the new window runs. `exec $SHELL` keeps the window open afterwards
# so the owner can read the transcript and resume.
INNER=$(printf 'cd %q && claude --model %q --session-id %q %s %q; exec %q' \
  "$CWD" "$MODEL" "$SID" "${BUILDER_CLAUDE_ARGS:-}" "$PROMPT" "$SHELL_BIN")

have() { command -v "$1" >/dev/null 2>&1; }
# wezterm/ghostty ship as .app bundles on macOS and are often not on PATH.
find_mac_bin() { [ -x "/Applications/$1.app/Contents/MacOS/$2" ] && echo "/Applications/$1.app/Contents/MacOS/$2"; }

term="${BUILDER_TERMINAL:-}"
if [ -z "$term" ]; then
  for t in wezterm ghostty kitty alacritty iterm terminal gnome-terminal konsole xterm tmux; do
    case "$t" in
      wezterm) have wezterm || find_mac_bin WezTerm wezterm >/dev/null || continue;;
      ghostty) have ghostty || find_mac_bin Ghostty ghostty >/dev/null || continue;;
      iterm)   [ -d /Applications/iTerm.app ] || continue;;
      terminal) [ "$(uname)" = Darwin ] || continue;;
      *) have "$t" || continue;;
    esac
    term="$t"; break
  done
fi
[ -n "$term" ] || { echo "no terminal found; set BUILDER_TERMINAL" >&2; exit 1; }

if [ -n "$DRY" ]; then echo "terminal=$term"; echo "inner=$INNER"; exit 0; fi

case "$term" in
  wezterm)
    bin="$(command -v wezterm || find_mac_bin WezTerm wezterm)"
    "$bin" start --always-new-process --cwd "$CWD" -- "$SHELL_BIN" -lc "$INNER" & ;;
  ghostty)
    bin="$(command -v ghostty || find_mac_bin Ghostty ghostty)"
    "$bin" -e "$SHELL_BIN" -lc "$INNER" & ;;
  kitty)     kitty --detach --directory "$CWD" "$SHELL_BIN" -lc "$INNER";;
  alacritty) alacritty --working-directory "$CWD" -e "$SHELL_BIN" -lc "$INNER" & ;;
  iterm)     osascript -e 'tell application "iTerm" to create window with default profile command "'"$SHELL_BIN"' -lc '"$(printf '%q' "$INNER")"'"' >/dev/null;;
  terminal)  osascript -e 'tell application "Terminal" to do script '"$(printf '%q' "$INNER")"'' >/dev/null;;
  gnome-terminal) gnome-terminal --working-directory="$CWD" -- "$SHELL_BIN" -lc "$INNER";;
  konsole)   konsole --workdir "$CWD" -e "$SHELL_BIN" -lc "$INNER" & ;;
  xterm)     xterm -e "$SHELL_BIN" -lc "$INNER" & ;;
  # ponytail: tmux is the headless fallback — no window pops up, owner attaches manually.
  tmux)      tmux new-session -d -s "builder-${SID:0:8}" -c "$CWD" "$SHELL_BIN" -lc "$INNER"
             echo "attach with: tmux attach -t builder-${SID:0:8}" >&2;;
esac

echo "$SID"
