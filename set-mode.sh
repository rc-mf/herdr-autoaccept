#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

mode="${1:?usage: set-mode.sh off|list|all}"
f="$(state_file)"

# The watchlist's per-pane indicator only means something in "list" mode —
# in "off"/"all" every pane behaves the same way regardless of the list.
if [ "$mode" = "list" ]; then
  while IFS= read -r pane_id; do
    mark_watched "$pane_id"
  done < <(jq -r '.panes[]' "$f")
else
  while IFS= read -r pane_id; do
    mark_unwatched "$pane_id"
  done < <(jq -r '.panes[]' "$f")
fi

state_write "$f" --arg m "$mode" '.mode = $m'
notify "Auto-accept mode: $mode"
