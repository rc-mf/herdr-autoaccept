#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

status="$(printf '%s' "$HERDR_PLUGIN_EVENT_JSON" | jq -r '.data.agent_status // empty')"

[ "$status" = "blocked" ] || exit 0

pane_id="${HERDR_PANE_ID:-}"

[ -n "$pane_id" ] || exit 0

f="$(state_file)"
mode="$(jq -r '.mode' "$f")"

case "$mode" in
  all)
    ;;
  list)
    jq -e --arg p "$pane_id" '.panes | index($p) != null' "$f" >/dev/null || exit 0
    ;;
  *)
    exit 0
    ;;
esac

herdr pane run "$pane_id" "" >/dev/null 2>&1
notify "Auto-accepted $pane_id"
