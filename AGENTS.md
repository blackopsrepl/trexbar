# AGENTS.md

Guidance for Codex and other coding agents working in this repository.

## Rules

- Keep `trexbar` read-only for tmux state unless a later plan explicitly changes that contract.
- Waybar render commands must read cached state only. Do not run `tmux`, scan `/proc`, or call `trex snapshot --json` from `waybar render`.
- The Ruby app consumes `trex snapshot --json`; it does not duplicate `trex` backend logic.
- For SolverForge Linux integration, edit the managed default layer under `~/.local/share/solverforge/`, not symlinked `~/.config/waybar` files.
- Omarchy shell integration must edit `~/.config/omarchy/shell.json` only through `Runtime::Omarchy` (the `omarchy` CLI command); never hand-edit the seeded layout elsewhere.
- Keep `README.md`, `WIREFRAME.md`, `docs/*.md`, and this file aligned with the shipped CLI, cached-state contract, QuickShell UI, and detected agents (Codex, Gemini, Hermes).
- When a task is simple, do the simple thing. Do not expand scope into unrelated critical paths.

## Validation

Run:

```bash
ruby test/run.rb
ruby -c bin/trexbar
make check-trex
bash -n packaging/solverforge-linux/solverforge-waybar-trexbar
rg -n "trexbar|snapshot|waybar|QuickShell|WIREFRAME" README.md WIREFRAME.md docs AGENTS.md
```
