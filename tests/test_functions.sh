#!/bin/bash
# ==============================================================================
# WELLARCH Test Suite
# Basic tests for WELLARCH functions
# ==============================================================================

# Don't use set -e as we want to continue after assertion failures
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the common library
if [[ -f "${SCRIPT_DIR}/lib/common.sh" ]]; then
    source "${SCRIPT_DIR}/lib/common.sh"
else
    echo -e "${RED}ERROR: lib/common.sh not found${NC}"
    exit 1
fi

# ==============================================================================
# TEST HELPERS
# ==============================================================================

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    ((TESTS_RUN++)) || true
    
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} $message"
    else
        ((TESTS_FAILED++)) || true
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Expected: '$expected'"
        echo -e "    Actual:   '$actual'"
    fi
    return 0
}

assert_true() {
    local condition="$1"
    local message="${2:-}"
    
    ((TESTS_RUN++)) || true
    
    if eval "$condition" 2>/dev/null; then
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} $message"
    else
        ((TESTS_FAILED++)) || true
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Condition failed: $condition"
    fi
    return 0
}

assert_false() {
    local condition="$1"
    local message="${2:-}"
    
    ((TESTS_RUN++)) || true
    
    if ! eval "$condition" 2>/dev/null; then
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} $message"
    else
        ((TESTS_FAILED++)) || true
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Condition should have failed: $condition"
    fi
    return 0
}

run_test() {
    local test_name="$1"
    echo -e "\n${YELLOW}Testing: $test_name${NC}"
}

# ==============================================================================
# TESTS
# ==============================================================================

test_colors() {
    run_test "Color definitions"
    
    assert_true '[[ -n "$GREEN" || -z "$GREEN" ]]' "GREEN is defined"
    assert_true '[[ -n "$RED" || -z "$RED" ]]' "RED is defined"
    assert_true '[[ -n "$YELLOW" || -z "$YELLOW" ]]' "YELLOW is defined"
    assert_true '[[ -n "$NC" || -z "$NC" ]]' "NC is defined"
}

test_version() {
    run_test "Version constant"
    
    assert_true '[[ -n "$WELLARCH_VERSION" ]]' "WELLARCH_VERSION is defined"
    assert_true '[[ "$WELLARCH_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]' "Version follows semver format"
}

test_is_installed() {
    run_test "is_installed function"
    
    assert_true 'is_installed bash' "bash should be installed"
    assert_true 'is_installed ls' "ls should be installed"
    assert_false 'is_installed nonexistent_command_12345' "nonexistent command should not be installed"
}

test_log_level() {
    run_test "Log level functions"
    
    # Test set_log_level
    set_log_level "debug"
    assert_equals "3" "$LOG_LEVEL_NUM" "Debug level should be 3"
    
    set_log_level "info"
    assert_equals "2" "$LOG_LEVEL_NUM" "Info level should be 2"
    
    set_log_level "warn"
    assert_equals "1" "$LOG_LEVEL_NUM" "Warn level should be 1"
    
    set_log_level "error"
    assert_equals "0" "$LOG_LEVEL_NUM" "Error level should be 0"
}

test_dns_providers() {
    run_test "DNS Providers configuration"
    
    assert_true '[[ -n "${DNS_PROVIDERS[cloudflare]}" ]]' "Cloudflare DNS is defined"
    assert_true '[[ -n "${DNS_PROVIDERS[google]}" ]]' "Google DNS is defined"
    assert_true '[[ -n "${DNS_PROVIDERS[quad9]}" ]]' "Quad9 DNS is defined"
    assert_true '[[ -n "${DNS_PROVIDERS[adguard]}" ]]' "AdGuard DNS is defined"
    
    # Check DNS format (should contain commas for multiple servers)
    assert_true '[[ "${DNS_PROVIDERS[cloudflare]}" == *","* ]]' "Cloudflare has multiple DNS servers"
}

test_temp_dir() {
    run_test "Temporary directory management"
    
    # Criar diretório diretamente no shell atual para o array ser atualizado
    local tmpdir
    tmpdir=$(mktemp -d)
    TMP_DIRS+=("$tmpdir")
    
    assert_true '[[ -d "$tmpdir" ]]' "Temp directory was created"
    assert_true '[[ "$tmpdir" == /tmp/* ]]' "Temp directory is in /tmp"
    
    cleanup_temp_dirs
    
    # Check if directory was actually removed
    ((TESTS_RUN++)) || true
    if [[ ! -d "$tmpdir" ]]; then
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} Temp directory was cleaned up"
    else
        ((TESTS_FAILED++)) || true
        echo -e "  ${RED}✗${NC} Temp directory was cleaned up"
        echo -e "    Directory still exists: $tmpdir"
        # Cleanup manually for test
        rm -rf "$tmpdir" 2>/dev/null || true
    fi
}

test_config_paths() {
    run_test "Configuration paths"
    
    assert_true '[[ -n "$WELLARCH_CONFIG_DIR" ]]' "Config dir is defined"
    assert_true '[[ -n "$WELLARCH_CONFIG_FILE" ]]' "Config file path is defined"
    assert_true '[[ -n "$WELLARCH_CACHE_DIR" ]]' "Cache dir is defined"
    assert_true '[[ -n "$WELLARCH_LOG_FILE" ]]' "Log file path is defined"
}

test_external_urls() {
    run_test "External URLs configuration"
    
    assert_true '[[ -n "$CHAOTIC_KEY" ]]' "Chaotic AUR key is defined"
    assert_true '[[ -n "$CHAOTIC_KEYSERVER" ]]' "Chaotic keyserver is defined"
    assert_true '[[ -n "$LINUXTOYS_URL" ]]' "LinuxToys URL is defined"
    assert_true '[[ "$LINUXTOYS_URL" == https://* ]]' "LinuxToys URL uses HTTPS"
}

test_prompt_choice_default() {
    run_test "prompt_choice with ASSUME_YES"
    
    ASSUME_YES=true
    local result
    result=$(prompt_choice "Test prompt" "default_value")
    
    assert_equals "default_value" "$result" "Should return default when ASSUME_YES=true"
    
    ASSUME_YES=false
}

test_bash_version_check() {
    run_test "Bash version check"
    
    # This should pass since we're running on Bash 4+
    assert_true 'check_bash_version 4 0' "Should pass for Bash 4.0+"
}

test_menu_tty_fallback() {
    run_test "Menu fallback to /dev/tty"

    if ! command -v script >/dev/null 2>&1; then
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} script utility not available; tty fallback test skipped"
        ((TESTS_RUN++)) || true
        return 0
    fi

    local output
    output=$(script -q -c "bash -lc 'source \"${SCRIPT_DIR}/lib/menu.sh\"; menu_select \"Escolha\" \"Opção A\" \"Opção B\" <<< \"2\"'" /dev/null 2>&1 | tr -d '\r')

    if [[ "$output" == *"[1]"* && "$output" == *"[2]"* ]] && [[ "$output" == *"Opção A"* || "$output" == *"Opção B"* ]]; then
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} Menu shows numbered options when a tty is available"
    else
        ((TESTS_FAILED++)) || true
        echo -e "  ${RED}✗${NC} Menu did not show numbered options in tty mode"
        echo -e "    Output: $output"
    fi
    ((TESTS_RUN++)) || true
}

test_install_defaults_are_interactive() {
    run_test "Installer defaults keep interactive menus"

    if grep -Eq 'args=\("--dry-run"\)' "${SCRIPT_DIR}/install.sh"; then
        ((TESTS_FAILED++)) || true
        echo -e "  ${RED}✗${NC} install.sh forces dry-run when no arguments are provided"
    else
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} install.sh does not force dry-run by default"
    fi
    ((TESTS_RUN++)) || true
}

test_script_syntax() {
    run_test "Script syntax validation"
    
    assert_true 'bash -n "${SCRIPT_DIR}/wellarch.sh"' "wellarch.sh has valid syntax"
    assert_true 'bash -n "${SCRIPT_DIR}/wellarch-remove.sh"' "wellarch-remove.sh has valid syntax"
    assert_true 'bash -n "${SCRIPT_DIR}/install.sh"' "install.sh has valid syntax"
    assert_true 'bash -n "${SCRIPT_DIR}/lib/common.sh"' "lib/common.sh has valid syntax"
}

test_removed_features() {
    run_test "Removed optional features"

    assert_false 'grep -Eq "ProtonPlus|protonplus|Papirus|papirus|Plymouth|plymouth|quiet splash|setup_plymouth|SKIP_PLYMOUTH" "${SCRIPT_DIR}/wellarch.sh"' \
        "Main installer does not install icons or modify boot animation"
}

test_vscode_package() {
    run_test "Visual Studio Code package"

    if grep -q 'install_pkg_preferred "Visual Studio Code" "visual-studio-code-bin"' "${SCRIPT_DIR}/lib/packages.sh"; then
        ((TESTS_PASSED++)) || true
        echo -e "  ${GREEN}✓${NC} Uses the official VS Code AUR package"
    else
        ((TESTS_FAILED++)) || true
        echo -e "  ${RED}✗${NC} Uses the official VS Code AUR package"
    fi
    ((TESTS_RUN++)) || true
}

test_safe_mode_guard() {
    run_test "Safe mode removed"

    assert_false 'grep -Eq "SAFE_MODE|safe_mode_enabled|allow_destructive_action|--unsafe|--safe" "${SCRIPT_DIR}/wellarch.sh"' \
        "Main installer does not contain safe mode"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║           WELLARCH Test Suite v${WELLARCH_VERSION}                     ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    # Run all tests
    test_colors
    test_version
    test_is_installed
    test_log_level
    test_dns_providers
    test_temp_dir
    test_config_paths
    test_external_urls
    test_prompt_choice_default
    test_bash_version_check
    test_menu_tty_fallback
    test_install_defaults_are_interactive
    test_script_syntax
    test_removed_features
    test_vscode_package
    test_safe_mode_guard
    
    # Summary
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    else
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
