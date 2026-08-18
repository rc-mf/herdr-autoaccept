#!/usr/bin/env bash
# Shared state helpers. state.json shape: {"mode": "off"|"list"|"all", "panes": ["w1:p2", ...]}

state_file() {
  local dir="${HERDR_PLUGIN_STATE_DIR:?HERDR_PLUGIN_STATE_DIR not set — run inside a Herdr plugin process}"
  mkdir -p "$dir"

  local f="$dir/state.json"

  [ -f "$f" ] || echo '{"mode":"list","panes":[]}' > "$f"

  echo "$f"
}

state_write() {
  local f="$1"
  shift

  local tmp="$f.tmp"

  jq "$@" "$f" > "$tmp" && mv "$tmp" "$f"
}

notify() {
  herdr notification show "$1" --position top-right --sound none >/dev/null 2>&1 || true
}

mark_watched() {
  herdr pane report-metadata "$1" --source autoaccept --token "summary=auto-accept" >/dev/null 2>&1 || true
}

mark_unwatched() {
  herdr pane report-metadata "$1" --source autoaccept --clear-token summary >/dev/null 2>&1 || true
}
