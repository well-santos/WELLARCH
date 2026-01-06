SHELL := /bin/bash

.PHONY: lint format check install-tools

lint:
	@echo "Running shellcheck and shfmt checks..."
	@shellcheck -x wellarch.sh
	@shfmt -l wellarch.sh

format:
	@echo "Formatting with shfmt..."
	@shfmt -w wellarch.sh

check: lint
	@echo "Running syntax check..."
	@bash -n wellarch.sh

install-tools:
	@echo "Installing shellcheck and shfmt (pacman/apt supported)..."
	@if command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --needed shellcheck shfmt --noconfirm; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck shfmt; \
	else \
		echo "Please install shellcheck and shfmt manually."; exit 1; \
	fi
