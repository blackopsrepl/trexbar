# Architecture

`trexbar` has four active layers:

1. Ruby CLI.
2. Ruby runtime for config, refresh, cached state, and presentation.
3. Runtime files in `~/.local/state/trexbar`.
4. Waybar JSON chip plus QuickShell detail modal.

The backend boundary is `trex snapshot --json`. The frontend and Waybar never run tmux commands directly.

`refresh`, `snapshot`, and the daemon are the only paths that invoke the `trex` backend. `waybar render` reads the cached `snapshot.json`, derives stale state locally, and emits Waybar JSON without touching tmux, `/proc`, git, or `trex`.

The shipped UI and file-level runtime contract are documented in `WIREFRAME.md`.
