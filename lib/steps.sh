#!/bin/bash
# ==============================================================================
# WELLARCH Step-Oriented Helpers
# Provides stage-gated wrappers for major installation steps.
# ==============================================================================

step_before() {
    local step_name="$1"
    local gate_condition="$2"

    if [[ -n "$gate_condition" ]] && ! eval "$gate_condition" 2>/dev/null; then
        echo -e "${AMARELO}⏭️  Pulando etapa: $step_name${NC}"
        return 1
    fi

    return 0
}

step_should_skip() {
    local flag_name="$1"
    if [[ "${!flag_name:-false}" == true ]]; then
        return 0
    fi
    return 1
}

step_warn_skip() {
    local step_name="$1"
    local flag_name="$2"

    if step_should_skip "$flag_name"; then
        echo -e "${AMARELO}⏭️  Pulando ${step_name} (--${flag_name#SKIP_})${NC}"
        return 0
    fi

    return 1
}
