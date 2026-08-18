# herdr-autoaccept

A [herdr](https://herdr.dev) plugin that hits Enter automatically on panes you've
opted in to watch, whenever they go `blocked`. Built to replace a hand-rolled
polling script (`while true; do herdr agent wait ...; done`) with a proper
herdr event hook.

Requires **herdr >= 0.8.0** (uses `herdr pane report-metadata --token`, which
doesn't exist on older versions).

## Install

```
herdr plugin install <owner>/herdr-autoaccept
```

Then add the keybind and sidebar indicator to your own
`~/.config/herdr/config.toml` — plugin install does not touch your config:

```toml
[[keys.command]]
key = "prefix+shift+a"
type = "plugin_action"
command = "autoaccept.toggle-watch"
description = "toggle auto-accept watch on this pane"

[ui.sidebar.agents]
rows = [["state_icon", "workspace", "tab"], ["agent"], ["$summary"]]
```

The sidebar row is optional but recommended — without it there's no visual
indicator of which panes are being watched. It's additive to whatever rows
you already have; adjust to fit your existing config.

Reload with `herdr server reload-config`.

## Usage

- **`prefix+shift+a`** (or `herdr plugin action invoke toggle-watch`) — toggle
  the currently focused pane in/out of the watchlist. Watched panes show
  `auto-accept` in the sidebar.
- **`herdr plugin action invoke watch-all`** — auto-accept every pane in the
  session, ignoring the watchlist.
- **`herdr plugin action invoke watch-list`** — go back to opt-in watchlist
  mode.
- **`herdr plugin action invoke off`** — turn off entirely (watchlist is
  preserved, nothing gets auto-accepted).

Default mode is `list` with an empty watchlist, so installing the plugin
does nothing until you explicitly watch a pane.

## How it works

`herdr-plugin.toml` declares an `[[events]] on = "pane.agent_status_changed"`
hook. Herdr fires this for *every* pane's status change, session-wide — there's
no manifest-level filter by pane or workspace. `on-status-changed.sh` does the
filtering itself: it reads `state.json` (in `$HERDR_PLUGIN_STATE_DIR`) and only
runs `herdr pane run <pane_id> ""` (send Enter) if the pane is in the
watchlist (`mode = "list"`) or `mode = "all"`.

State shape:

```json
{"mode": "off" | "list" | "all", "panes": ["w1:p2", ...]}
```

## Caveats

- The event hook fires globally, not scoped to your workspace — the plugin
  filters after the fact rather than herdr filtering before invoking it.
- Auto-accepting is inherently blind: it hits Enter without reading what the
  pane is actually asking. Only watch panes you'd trust to auto-approve.
