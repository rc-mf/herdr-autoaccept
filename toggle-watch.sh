#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

pane_id="${HERDR_PANE_ID:?HERDR_PANE_ID not set}"
f="$(state_file)"

if jq -e --arg p "$pane_id" '.panes | index($p) != null' "$f" >/dev/null; then
  state_write "$f" --arg p "$pane_id" '.panes -= [$p]'
  mark_unwatched "$pane_id"
  notify "Auto-accept: stopped watching this pane"
else
  state_write "$f" --arg p "$pane_id" '.panes += [$p]'
  mark_watched "$pane_id"
  notify "Auto-accept: now watching this pane"
fi
