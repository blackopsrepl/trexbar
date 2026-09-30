# CLI

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

Behavior notes:

- `snapshot` refreshes cached state and always prints JSON.
- `refresh` refreshes cached state and prints JSON only with `--format json`.
- `daemon --once` performs one refresh and exits.
- `waybar render` reads cached state only.
- `waybar refresh` refreshes cached state.
- `waybar panel` opens the QuickShell modal.
- `omarchy install` mounts the Waybar chip as an Omarchy shell bar command module in `~/.config/omarchy/shell.json`, by default after `omarchy.weather`; it seeds the user file from the Omarchy defaults when missing. The generated `render`, `panel`, and `refresh` commands record the resolved `--config` path, so the chip reads the same cached state as the daemon.
- `omarchy remove` drops the module from the user shell config.
- `omarchy status` reports whether the module is installed and where.

`omarchy install` flags:

- `--after ID` — anchor widget id to insert after (default `omarchy.weather`; an id that is not on the bar falls back to the end of the center section)
- `--section left|center|right` — explicit target section
- `--index N` — explicit position inside `--section` (must be within `0..length`)
- `--interval SECONDS` — render poll interval (default 5)
- `--exec PATH` — alternate `trexbar` binary to record in the module commands
