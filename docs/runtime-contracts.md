# Runtime Contracts

## Config

Default path:

```text
~/.config/trexbar/config.json
```

Important fields:

- `runtime.stateDir`
- `runtime.refreshSeconds`
- `runtime.waybarSignal`
- `runtime.trexCommand`
- `runtime.quickShellCommand`
- `runtime.quickShellShell`
- `display.maxSessions`
- `display.staleAfterSeconds`

`runtime.trexCommand` is the path or command name for the required `trex` executable. The executable must support `snapshot --json`.

`display.maxSessions` limits the number of session rows rendered into the Waybar tooltip.

## Snapshot

Default path:

```text
~/.local/state/trexbar/snapshot.json
```

The Ruby runtime owns this file. `refresh`, `snapshot`, and the daemon write it. QuickShell and Waybar read it.

The cached snapshot includes the backend payload plus a derived `view` object used by the chip and modal:

- `chip.text`
- `chip.tooltipLines`
- `chip.classes`
- `summary`
- `headlineSession`
- `sessions`
- `agents`
- `errors`

## UI State

Default path:

```text
~/.local/state/trexbar/ui.json
```

Shape:

```json
{"open":true,"requestedAt":"2026-05-08T00:00:00Z"}
```

QuickShell reads this file to decide whether the modal is visible. `trexbar ui open|close|toggle` writes it.

## Watch Event

Default path:

```text
~/.local/state/trexbar/state-event.json
```

Each snapshot or UI-state write updates this file so the QuickShell frontend can reload both JSON files.

## Waybar

Command:

```bash
trexbar waybar render
```

Shape:

```json
{"text":"TRX 3 1a 2ai","tooltip":"...","class":["trexbar","healthy"]}
```

`waybar render` emits a loading payload when no cached snapshot exists. It marks cached snapshots stale when `snapshot.generatedAt` is older than `display.staleAfterSeconds`.
