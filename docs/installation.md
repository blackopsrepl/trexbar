# Installation

`trexbar` depends on `trex snapshot --json`. Install or build `trex` first, then verify the dependency:

```bash
make check-trex
```

Install the app under the user prefix:

```bash
make install-user
```

Install the SolverForge Linux Waybar wrapper:

```bash
make install-solverforge
```

Desktop module wiring lives in the SolverForge Linux default layer, not in symlinked `~/.config/waybar` files.

`install-user` installs `README.md`, `WIREFRAME.md`, `AGENTS.md`, `docs/`, `frontend/`, `packaging/`, `assets/`, `bin/`, and `lib/` under `~/.local/share/trexbar`, then links `~/.local/bin/trexbar`.

## Upgrading from the previous name

The previous command was `trexbar-sway`. The new command is `trexbar`; there is no legacy command or environment-variable alias. Installation does not move or delete existing config, state, or app directories.

1. Stop the old daemon and close the old QuickShell modal before switching.
2. Run `make install-user` (and `make install-solverforge` for the SolverForge Linux wrapper).
3. Copy your old `~/.config/trexbar-sway/config.json` to `~/.config/trexbar/config.json`, creating the destination directory first. Update `runtime.stateDir` to `~/.local/state/trexbar` and `runtime.quickShellShell` to `~/.local/share/trexbar/frontend/quickshell/shell.qml`. Preserve other custom settings. For a fresh config instead, run `trexbar config init`.
4. Update desktop autostart and bar commands to `trexbar`. Replace `TREXBAR_SWAY_BIN`, `TREXBAR_SWAY_CONFIG`, and `TREXBAR_SWAY_STATE_DIR` overrides with `TREXBAR_BIN`, `TREXBAR_CONFIG`, and `TREXBAR_STATE_DIR`.
5. On Omarchy, run `trexbar omarchy install` with the same placement flags you used originally; this updates the existing `trexbar` module's commands without duplicating it.
6. Run `trexbar config validate`, then start `trexbar daemon`. The daemon regenerates cached state in the new directory; copying old caches or lock files is unnecessary.

An explicit `--config PATH` or custom `runtime.stateDir` still works unchanged. Remove the old installation only after the new one is working.
