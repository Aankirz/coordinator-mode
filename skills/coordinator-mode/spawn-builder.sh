#!/usr/bin/env bash
# Spawn a Claude builder session in a new, visible terminal window.
# Usage: spawn-builder.sh [--cwd DIR] [--model M] [--name NAME] [--brief FILE | --prompt TEXT]
# Env:   BUILDER_TERMINAL  force a terminal (wezterm|ghostty|kitty|alacritty|iterm|terminal|gnome-terminal|konsole|xterm|tmux)
#        BUILDER_CLAUDE_ARGS  extra args passed through to `claude`
# Prints the session id on stdout so the coordinator can hand it to the owner.
set -euo pipefail

CWD="$PWD"; MODEL="opus"; NAME=""; PROMPT=""; BRIEF=""; DRY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) CWD="$2"; shift 2;;
    --model) MODEL="$2"; shift 2;;
    --name) NAME="$2"; shift 2;;
    --brief) BRIEF="$2"; shift 2;;
    --prompt) PROMPT="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
if [ -n "$BRIEF" ]; then
  case "$BRIEF" in /*) ;; *) BRIEF="$CWD/$BRIEF";; esac
  [ -r "$BRIEF" ] || { echo "brief not readable: $BRIEF" >&2; exit 2; }
  PROMPT="$(cat "$BRIEF")"
fi
[ -n "$PROMPT" ] || { echo "need --brief or --prompt" >&2; exit 2; }
[ -d "$CWD" ] || { echo "--cwd is not a directory: $CWD" >&2; exit 2; }

SID="$(uuidgen | tr 'A-Z' 'a-z')"
NAME="${NAME:-builder-${SID:0:8}}"
SHELL_BIN="${SHELL:-/bin/bash}"

# The command the new window runs. `exec $SHELL` keeps the window open afterwards
# so the owner can read the transcript and resume.
INNER=$(printf 'cd %q && claude --model %q --session-id %q --name %q %s %q; exec %q' \
  "$CWD" "$MODEL" "$SID" "$NAME" "${BUILDER_CLAUDE_ARGS:-}" "$PROMPT" "$SHELL_BIN")

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

case "$term" in
  wezterm) have wezterm || find_mac_bin WezTerm wezterm >/dev/null || { echo "wezterm not found" >&2; exit 1; };;
  ghostty) have ghostty || find_mac_bin Ghostty ghostty >/dev/null || { echo "ghostty not found" >&2; exit 1; };;
  iterm)   [ -d /Applications/iTerm.app ] || { echo "iTerm.app not found" >&2; exit 1; };;
  terminal) [ "$(uname)" = Darwin ] || { echo "Terminal.app needs macOS" >&2; exit 1; };;
  kitty|alacritty|gnome-terminal|konsole|xterm|tmux) have "$term" || { echo "$term not found on PATH" >&2; exit 1; };;
  *) echo "unsupported terminal: $term (wezterm|ghostty|kitty|alacritty|iterm|terminal|gnome-terminal|konsole|xterm|tmux)" >&2; exit 2;;
esac

have claude || { echo "claude not found on PATH" >&2; exit 1; }

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
  iterm)     osascript - "$INNER" >/dev/null <<'OSA'
on run argv
  tell application "iTerm"
    set w to (create window with default profile)
    tell current session of w to write text (item 1 of argv)
  end tell
end run
OSA
             ;;
  terminal)  osascript - "$INNER" >/dev/null <<'OSA'
on run argv
  tell application "Terminal"
    activate
    do script (item 1 of argv)
  end tell
end run
OSA
             ;;
  gnome-terminal) gnome-terminal --working-directory="$CWD" -- "$SHELL_BIN" -lc "$INNER";;
  konsole)   konsole --workdir "$CWD" -e "$SHELL_BIN" -lc "$INNER" & ;;
  xterm)     xterm -e "$SHELL_BIN" -lc "$INNER" & ;;
  # ponytail: tmux is the headless fallback — no window pops up, owner attaches manually.
  tmux)      tmux new-session -d -s "builder-${SID:0:8}" -c "$CWD" "$SHELL_BIN" -lc "$INNER"
             echo "attach with: tmux attach -t builder-${SID:0:8}" >&2;;
esac

echo "launch requested for $NAME; confirm it with ListAgents before relying on it" >&2
echo "$SID"
