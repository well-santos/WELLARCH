SHELL := /bin/bash

.PHONY: lint format check test install-tools help

# Default target
.DEFAULT_GOAL := help

help:
	@echo "WELLARCH Makefile - Available targets:"
	@echo ""
	@echo "  make lint          - Run shellcheck on all scripts"
	@echo "  make format        - Format scripts with shfmt"
	@echo "  make check         - Run syntax check and lint"
	@echo "  make test          - Run test suite"
	@echo "  make install-tools - Install shellcheck and shfmt"
	@echo "  make all           - Run check, test, and lint"
	@echo ""

lint:
	@echo "Running shellcheck..."
	@shellcheck -x wellarch.sh install.sh wellarch-remove.sh lib/common.sh
	@echo "Running shfmt check..."
	@shfmt -l -d wellarch.sh install.sh wellarch-remove.sh lib/common.sh || true
	@echo "✓ Lint complete"

format:
	@echo "Formatting with shfmt..."
	@shfmt -w -i 0 -ci wellarch.sh install.sh wellarch-remove.sh lib/common.sh
	@echo "✓ Format complete"

check: lint
	@echo "Running syntax check..."
	@bash -n wellarch.sh
	@bash -n install.sh
	@bash -n wellarch-remove.sh
	@bash -n lib/common.sh
	@echo "✓ Syntax check complete"

test:
	@echo "Running test suite..."
	@chmod +x tests/test_functions.sh
	@bash tests/test_functions.sh
	@echo "✓ Tests complete"

install-tools:
	@echo "Installing shellcheck and shfmt..."
	@if command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --needed shellcheck shfmt --noconfirm; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck shfmt; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install shellcheck shfmt; \
	else \
		echo "Please install shellcheck and shfmt manually."; exit 1; \
	fi
	@echo "✓ Tools installed"

all: check test lint
	@echo "✓ All checks passed"

# Development helpers
dry-run:
	@./wellarch.sh --dry-run --yes

dry-run-verbose:
	@./wellarch.sh --dry-run --yes --verbose
