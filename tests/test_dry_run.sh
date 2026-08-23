#!/bin/bash
# ============================================================================
# Dry-run guard tests
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

DRY_RUN=true

sudo_run touch "$TEST_DIR/sudo-file"
sudo_run_retry "test command" touch "$TEST_DIR/retry-file"

if [[ -e "$TEST_DIR/sudo-file" || -e "$TEST_DIR/retry-file" ]]; then
	echo "Dry-run guard failed: a mutating command was executed."
	exit 1
fi

echo "Dry-run guards passed."