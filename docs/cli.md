# CLI

```text
trexbar-sway config init|validate
trexbar-sway snapshot
trexbar-sway refresh
trexbar-sway daemon [--once]
trexbar-sway panel
trexbar-sway ui open|close|toggle|status
trexbar-sway waybar render|refresh|panel
trexbar-sway omarchy install|remove|status
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
- `omarchy install` mounts the Waybar chip as an Omarchy shell bar command module in `~/.config/omarchy/shell.json`, by default after `omarchy.weather`; it seeds the user file from the Omarchy defaults when missing.
- `omarchy remove` drops the module from the user shell config.
- `omarchy status` reports whether the module is installed and where.

`omarchy install` flags:

- `--after ID` — anchor widget id to insert after (default `omarchy.weather`; an id that is not on the bar falls back to the end of the center section)
- `--section left|center|right` — explicit target section
- `--index N` — explicit position inside `--section` (must be within `0..length`)
- `--interval SECONDS` — render poll interval (default 5)
- `--exec PATH` — alternate `trexbar-sway` binary to record in the module commands
