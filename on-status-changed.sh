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

# Herdr's own detection manifest names which rule made it "blocked" —
# bash_permission_prompt/generic_permission_prompt are the plain
# do-you-want-to-proceed Yes/No tool-approval dialogs. Anything else
# (multi-choice menus, workflow prompts, the broad legacy catch-all) is
# left for a human instead of blindly sending Enter.
rule_id="$(herdr agent explain "$pane_id" --json 2>/dev/null | jq -r '.matched_rule.id // empty')"

is_safe=false

case "$rule_id" in
  bash_permission_prompt | generic_permission_prompt) is_safe=true ;;
esac

# Fall back to the structural check for prompts herdr's own rules miss
# (e.g. the network-sandbox "do you want to allow this connection?" dialog),
# which otherwise only match the broad legacy_no_prompt_blocker catch-all.
if [ "$is_safe" != true ] && is_yes_no_menu "$pane_id"; then
  is_safe=true
fi

if [ "$is_safe" = true ]; then
  herdr pane run "$pane_id" "" >/dev/null 2>&1
  notify "Auto-accepted $pane_id"
else
  notify "Auto-accept skipped on $pane_id (${rule_id:-unrecognized}) — needs a look"
fi
