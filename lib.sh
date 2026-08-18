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

# Claude Code renders every simple accept/deny dialog (bash commands, network
# requests, file writes, ...) as the same numbered menu regardless of the
# question's wording: "1. Yes" / "2. Yes, don't ask again ..." / "3. No, ...".
# Match that shape rather than the question text, because herdr's own detection
# rules key on wording and miss variants — the network-sandbox "do you want to
# allow this connection?" prompt only hits its broad legacy catch-all.
#
# Patterns are POSIX ERE on purpose: this runs as a plugin subprocess with the
# system /usr/bin/grep (BSD), which has no -P/PCRE and no \s.
#
# Leading [^0-9]* absorbs the box chrome and cursor ("│ ❯ "); the trailing
# [^[:alnum:]]* absorbs padding and the closing "│".
is_yes_no_menu() {
  local text opts

  text="$(herdr pane read "$1" --source visible --lines 40 2>/dev/null)" || return 1

  opts="$(printf '%s\n' "$text" | grep -E '^[^0-9]*[0-9]+\.[[:space:]]' || true)"

  [ -n "$opts" ] || return 1

  # The first choice must be a bare "Yes" — not "1. Yesterday's backup".
  printf '%s\n' "$opts" | grep -qE '^[^0-9]*1\.[[:space:]]*[Yy]es[^[:alnum:]]*$' || return 1

  # Every choice must be a yes/no variant. Anything else (a filename, a model,
  # a branch) means this is a real decision, not an approval — leave it alone.
  ! printf '%s\n' "$opts" |
    grep -qvE '^[^0-9]*[0-9]+\.[[:space:]]*([Yy]es|[Nn]o)([^[:alnum:]].*)?$'
}

mark_watched() {
  herdr pane report-metadata "$1" --source autoaccept --token "summary=auto-accept" >/dev/null 2>&1 || true
}

mark_unwatched() {
  herdr pane report-metadata "$1" --source autoaccept --clear-token summary >/dev/null 2>&1 || true
}
