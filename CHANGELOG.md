# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## [0.2.0](https://github.com/blackopsrepl/trexbar-sway/compare/v0.1.4...v0.2.0) (2026-09-30)


### ⚠ BREAKING CHANGES

* replace trexbar-sway with trexbar and TREXBAR_SWAY_* overrides with TREXBAR_*. Default config, state, and installation paths now use trexbar. Existing installations require the documented migration; no legacy aliases or automatic file moves are provided.

### Features

* rebrand the desktop companion to trexbar a25001e

## [0.1.4](https://github.com/blackopsrepl/trexbar-sway/compare/v0.1.3...v0.1.4) (2026-09-28)

### Features

* **omarchy:** mount the Waybar chip as an Omarchy shell bar module 0f02acb
* **ui:** follow the active Omarchy theme 88c34df

### Bug Fixes

* **omarchy:** record the selected config in mounted module commands 98e3eac
* **omarchy:** reject explicit section indexes past the list 41f1277, references Array#insert
* **ui:** resolve the companion binary to an absolute path d93ec0a

## [0.1.3](https://github.com/blackopsrepl/trexbar-sway/compare/v0.1.2...v0.1.3) (2026-09-17)


### Features

* **ui:** square the panel and add motion polish 35aef70

## [0.1.2](///compare/v0.1.1...v0.1.2) (2026-05-16)


### Features

* **quickshell:** render structured footer chips bdcae3e


### Bug Fixes

* **quickshell:** match sibling modal geometry e40f8b0

## 0.1.2 (2026-05-16)


### Features

* render structured QuickShell agent and backend-error footer chips


### Bug Fixes

* match sibling QuickShell modal geometry


### Documentation

* align wireframe and runtime docs with detected agent footer behavior

## 0.1.1 (2026-05-16)


### Features

* add trexbar sway companion 0eee611
* add tyrannosaurus modal mark 8236987


### Bug Fixes

* honor configured waybar session limit 3dcf213
