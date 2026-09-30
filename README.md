# trexbar

<p align="center">
  <img src="assets/trexbar-mascot.png" alt="trexbar mascot" width="260">
</p>

`trexbar` is a read-only desktop companion for `trex`, supporting Waybar on Sway and Hyprland and the Omarchy shell. It uses `trex snapshot --json` as the backend contract, caches runtime state in Ruby, renders a compact Waybar chip, and opens a focused QuickShell modal.

![trexbar modal screenshot](assets/trexbar-screenshot.png)

V1 does not attach, switch, create, delete, or detach tmux sessions.

## Dependency

`trexbar` depends on a `trex` binary that supports:

```bash
trex snapshot --json
```

Set `runtime.trexCommand` in `~/.config/trexbar/config.json` when `trex` is not on `PATH`.

## Commands

```bash
trexbar config init
trexbar config validate
trexbar refresh --format json --pretty
trexbar daemon
trexbar daemon --once
trexbar snapshot
trexbar ui toggle
trexbar waybar render
trexbar waybar refresh
trexbar waybar panel
trexbar omarchy install
trexbar omarchy remove
trexbar omarchy status
trexbar panel
```

Use `make check-trex` to verify the backend dependency from this checkout.

## Desktop Autostart

`trexbar` has two separate runtime pieces:

- `trexbar daemon --config ~/.config/trexbar/config.json` refreshes `trex snapshot --json`, tmux, process, git, gemini, and resource state, then writes `snapshot.json`.
- `trexbar waybar render --config ~/.config/trexbar/config.json` reads that cached snapshot and returns Waybar JSON.

Waybar does not poll `trex`, tmux, `/proc`, or git by itself. If the daemon is not running after login or reboot, the Waybar chip can keep rendering, but it will render stale cached state. A desktop integration should therefore start and supervise the daemon at session startup.

On SolverForge Linux, the managed Waybar integration starts companion daemons through `solverforge-waybar-companions-start`, launched from Sway `exec_always` beside Waybar. That launcher restarts `trexbar daemon` if an early boot-time refresh failure makes it exit.

## Hyprland + Omarchy

On a Hyprland desktop running the Omarchy shell, the same Waybar chip mounts as a bar command module:

```bash
trexbar omarchy install   # adds the trexbar module next to omarchy.weather
trexbar omarchy status
trexbar omarchy remove
```

`omarchy install` seeds `~/.config/omarchy/shell.json` from the Omarchy defaults when the user file does not exist yet, inserts a `type: command` module (default placement: `--after omarchy.weather`), and asks the running shell to reload its config. The module polls `trexbar waybar render` on an interval (`--interval`, default 5), opens the QuickShell modal on left click, and refreshes cached state on middle click. The generated commands record the resolved `--config` path, so a daemon started with `--config` keeps the chip on the same state directory. The daemon itself is not started by the module; launch it at session startup, for example from Hyprland:

```ini
exec-once = trexbar daemon
```

The `waybar` chip contract is unchanged: Waybar on sway and the Omarchy shell on Hyprland both render the same cached-state JSON. The QuickShell modal follows the active Omarchy theme (live, via `theme/colors.toml`); outside Omarchy it keeps the built-in palette.

## Documentation

- `WIREFRAME.md`: shipped Waybar chip, QuickShell modal, CLI, state files, and wrapper contract.
- `docs/architecture.md`: runtime layers and backend boundary.
- `docs/cli.md`: command surface and global flags.
- `docs/runtime-contracts.md`: config, cached state, and Waybar JSON contracts.
- `docs/ui.md`: compact UI summary.
- `docs/installation.md`: user install and SolverForge Linux wrapper install.

## Runtime Files

- Config: `~/.config/trexbar/config.json`
- State: `~/.local/state/trexbar/`
- Snapshot: `snapshot.json`
- UI state: `ui.json`
- Watch event: `state-event.json`

Waybar rendering reads cached state only. Live tmux, `/proc`, git, and resource reads happen during `refresh` or in the daemon.
