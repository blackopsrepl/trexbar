PREFIX ?= $(HOME)/.local
APP_HOME ?= $(PREFIX)/share/trexbar
BIN_DIR ?= $(PREFIX)/bin
SOLVERFORGE_PATH ?= $(HOME)/.local/share/solverforge
TREX ?= trex

.PHONY: help test check-trex install-user install-solverforge release-check clean

help:
	@printf '%s\n' \
		'trexbar targets:' \
		'  test                Run Ruby tests' \
		'  check-trex          Verify trex snapshot --json dependency' \
		'  install-user        Install app under ~/.local' \
		'  install-solverforge Install SolverForge Linux Waybar wrapper' \
		'  release-check       Run local validation'

test:
	ruby test/run.rb

check-trex:
	"$(TREX)" snapshot --json >/dev/null

install-user:
	mkdir -p "$(APP_HOME)" "$(BIN_DIR)"
	cp -R bin lib frontend docs packaging assets README.md WIREFRAME.md AGENTS.md Makefile "$(APP_HOME)/"
	ln -sf "$(APP_HOME)/bin/trexbar" "$(BIN_DIR)/trexbar"
	chmod +x "$(APP_HOME)/bin/trexbar"

install-solverforge:
	mkdir -p "$(SOLVERFORGE_PATH)/bin"
	cp packaging/solverforge-linux/solverforge-waybar-trexbar "$(SOLVERFORGE_PATH)/bin/solverforge-waybar-trexbar"
	chmod +x "$(SOLVERFORGE_PATH)/bin/solverforge-waybar-trexbar"

release-check: test check-trex
	ruby -c bin/trexbar
	find lib test -name '*.rb' -print -exec ruby -c {} \;
	bash -n packaging/solverforge-linux/solverforge-waybar-trexbar

clean:
	rm -rf coverage
