#!/bin/sh
# Picks which editor opens for git (commit without -m, rebase -i, tag -a without -m).
# VS Code forks (Cursor, Windsurf, etc.) also set TERM_PROGRAM=vscode, so Cursor's
# own markers are checked first. Falls back to Cursor when nothing matches.
file="$1"

case "$VSCODE_GIT_ASKPASS_MAIN" in *[Cc]ursor*) is_cursor=1 ;; esac

if [ -n "$ZED_SESSION_ID" ] || [ "$TERM_PROGRAM" = "Zed" ]; then
    exec zed --wait "$file"
elif [ -n "$CURSOR_TRACE_ID" ] || [ -n "$is_cursor" ]; then
    exec cursor --wait "$file"
elif [ "$TERM_PROGRAM" = "vscode" ]; then
    exec code --wait "$file"
fi

exec cursor --wait "$file"
