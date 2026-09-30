# WIREFRAME.md

This document describes the shipped `trexbar` interface and runtime contract. It is a current-state wireframe for the Waybar chip, QuickShell modal, CLI controls, and cached files.

## Scope

`trexbar` is a read-only desktop companion for `trex`, supporting Waybar on Sway and Hyprland and the Omarchy shell.

It does:

- consume `trex snapshot --json` during `refresh`, `snapshot`, or daemon refresh work
- write cached state under `runtime.stateDir`
- render a Waybar custom-module JSON payload from cached state only
- launch a QuickShell modal that reads cached state and UI state files
- expose refresh and modal open/close/toggle commands

It does not:

- attach to tmux sessions
- switch sessions
- create, delete, or detach sessions
- scan tmux, `/proc`, git, or system stats from `waybar render`
- duplicate `trex` backend logic

## Waybar Chip

Renderer:

```bash
trexbar waybar render
```

Data source:

```text
~/.local/state/trexbar/snapshot.json
```

No cached snapshot:

```text
+----------------+
| TRX ...        |
+----------------+
class: trexbar loading
tooltip:
  trexbar is waiting for cached data.
  Middle click: refresh
```

Healthy snapshot:

```text
+----------------+
| TRX 10 8a 12ai |
+----------------+
class:
  trexbar
  healthy
  has-agents
  has-attached
  dirty-repos
  headline-attached
tooltip:
  trexbar
  Sessions: 10 | Attached: 8 | Agents: 12
  Activity: 2 active, 0 idle, 8 dormant
  <up to display.maxSessions session summary rows>
  <up to 4 backend error rows>
```

Text rules:

- `TRX err` when the snapshot status is `error`
- `TRX idle` when `summary.sessionCount` is zero
- `TRX <sessions>` when sessions exist
- append `<attached>a` when `summary.attachedCount` is positive
- append `<agents>ai` when `summary.agentCount` is positive

Stale snapshots use the normal cached payload with `stale` status/classes and `(stale)` in the tooltip header.

## QuickShell Modal

Launcher:

```bash
trexbar panel
trexbar waybar panel
trexbar ui open
```

Close controls:

```bash
trexbar ui close
Esc inside the modal
click outside the modal card
Close button
```

Top-level layout:

```text
Full-screen transparent overlay

                         +-----------------------------------------------+
                         | T-rex mark  trexbar              healthy      |
                         |      <headline session/meta>     [Refresh]    |
                         |      <snapshot generatedAt>      [Close]      |
                         +-----------------------------------------------+
                         | sessions | attached | agents | dirty repos    |
                         +-----------------------------------------------+
                         | sessions                                      |
                         |                         2 active 0 idle ...   |
                         | +-------------------------------------------+ |
                         | | status | name                 health      | |
                         | |        | git badge                         | |
                         | |        | activity age CPU RAM              | |
                         | +-------------------------------------------+ |
                         | | ... scrollable session rows ...           | |
                         +-----------------------------------------------+
                         | ACTIVE AGENTS                                 |
                         | [o codex/trex]  [o gemini/trex (2)]           |
                         |                                               |
                         | BACKEND ERRORS                                |
                         | [! backend failed]                            |
                         +-----------------------------------------------+
```

Header:

- fixed manga-like Tyrannosaurus mark
- title text `trexbar`
- headline session chosen by highest health severity, CPU, memory, and attached state
- snapshot `generatedAt`
- status pill using the snapshot status
- `Refresh` button runs `trexbar refresh`
- `Close` button writes UI state closed

Metric row:

- `sessions` from `summary.sessionCount`
- `attached` from `summary.attachedCount`
- `agents` from `summary.agentCount`
- `dirty repos` from `summary.dirtyRepoCount`

Session list:

- reads `view.sessions` from the cached snapshot
- row height is 72px
- attached rows get green-accent background and border
- detached rows alternate dark backgrounds
- left status rail color follows `health.level`
- first line shows session name and attached/detached state
- second line shows git status or `no git`
- third line shows activity level, activity age, CPU percent, and RAM MB
- right column shows health score

Footer:

- visible only when agents or errors exist
- uses a `ColumnLayout` to separate agents and errors
- `ACTIVE AGENTS` section:
  - renders agents as `AgentPill` components in a `Flow` layout (wraps to multiple lines)
  - pill shows a status dot (running/waiting), `processName / projectName`, and sub-agent count
  - pills are agent-agnostic and render whatever `trex` reports, including `codex`, `gemini`, and `hermes`
- `BACKEND ERRORS` section:
  - renders backend error messages as pill-shaped chips in a `Flow` layout

## State Files

Default directory:

```text
~/.local/state/trexbar
```

Files:

- `snapshot.json`: full cached snapshot plus derived `view`
- `ui.json`: modal open state and request timestamp
- `state-event.json`: update marker watched by QuickShell
- `daemon.lock`: daemon singleton lock
- `refresh.lock`: refresh serialization lock

`snapshot.json` shape:

```json
{
  "snapshotVersion": 1,
  "generatedAt": "2026-05-08T00:00:00Z",
  "backendGeneratedAt": 1778094236271,
  "status": "healthy",
  "summary": {},
  "sessions": [],
  "agents": [],
  "errors": [],
  "view": {
    "chip": {
      "text": "TRX 10 8a 12ai",
      "tooltipLines": [],
      "classes": []
    },
    "summary": {},
    "headlineSession": null,
    "sessions": [],
    "agents": [],
    "errors": []
  }
}
```

`ui.json` shape:

```json
{
  "open": true,
  "requestedAt": "2026-05-08T00:00:00Z"
}
```

## CLI Surface

```text
trexbar config init|validate
trexbar snapshot
trexbar refresh
trexbar daemon [--once]
trexbar panel
trexbar ui open|close|toggle|status
trexbar waybar render|refresh|panel
trexbar omarchy install|remove|status
```

Global flags:

- `--config PATH`
- `--format json|text`
- `--pretty`
- `--once`

Behavior:

- `snapshot` refreshes from `trex snapshot --json`, writes cache, and prints JSON
- `refresh` refreshes from `trex snapshot --json`, writes cache, and prints only when `--format json` is set
- `daemon` refreshes immediately and then every `runtime.refreshSeconds`
- `daemon --once` performs one refresh
- `waybar render` reads only cached state
- `waybar refresh` refreshes cached state
- `waybar panel` opens the QuickShell modal
- `ui open|close|toggle|status` manage only modal UI state

## Configuration Defaults

Default config path:

```text
~/.config/trexbar/config.json
```

Defaults:

```json
{
  "version": 1,
  "runtime": {
    "stateDir": "~/.local/state/trexbar",
    "refreshSeconds": 5,
    "waybarSignal": 11,
    "trexCommand": "~/.cargo/bin/trex if executable, otherwise trex",
    "quickShellCommand": "quickshell",
    "quickShellShell": "~/.local/share/trexbar/frontend/quickshell/shell.qml"
  },
  "display": {
    "maxSessions": 8,
    "staleAfterSeconds": 15
  }
}
```

Validation rejects empty runtime command paths, refresh intervals below 1 second, Waybar signals outside 1-31, and display values below 1.

## SolverForge Linux Wrapper

Wrapper:

```text
packaging/solverforge-linux/solverforge-waybar-trexbar
```

Default command mapping:

- no argument or `render`: `trexbar waybar render`
- `panel`, `details`, or `open`: `trexbar waybar panel`
- `refresh`: `trexbar refresh`
- unknown argument: render fallback

The wrapper resolves:

- `TREXBAR_CONFIG`, defaulting to `~/.config/trexbar/config.json`
- `TREXBAR_BIN`, defaulting to `~/.local/bin/trexbar`

## Documentation Surfaces

Keep these files synchronized when behavior changes:

- `README.md`: public overview, dependency, command examples, runtime files
- `WIREFRAME.md`: shipped UI and runtime contract
- `docs/architecture.md`: layer and boundary overview
- `docs/cli.md`: command surface
- `docs/runtime-contracts.md`: config, state files, Waybar JSON
- `docs/ui.md`: visual summary
- `docs/installation.md`: install and SolverForge Linux wrapper notes
- `AGENTS.md`: repo-local rules and validation commands
