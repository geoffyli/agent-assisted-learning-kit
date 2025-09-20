#!/bin/bash

# Plan Phase Prerequisites Validation Script
# Validates that SCOPE phase is complete and ready for PLAN phase

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="${VAULT_ROOT:-}"
JSON_MODE=false
SESSION_PATH="" # Initialize SESSION_PATH

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] \"SESSION_PATH\""
            echo "Validates that SCOPE phase is complete for plan phase"
            exit 0 
            ;;
        *) SESSION_PATH="$arg" ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    if ! $JSON_MODE; then
        echo -e "${BLUE}[PLAN-PREREQ]${NC} $1"
    fi
}

warn() {
    if ! $JSON_MODE; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

error() {
    if ! $JSON_MODE; then
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

success() {
    if ! $JSON_MODE; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

# Function to detect vault root
detect_vault_root() {
    local current_dir="$PWD"
    
    # Look for vault indicators (AGENTS.md, docs/ directory)
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/AGENTS.md" && -d "$current_dir/docs" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    return 1
}

# Function to output JSON results
output_result() {
    local success="$1"
    local errors_json="$2"
    local warnings_json="$3"
    local session_status="$4"
    
    if $JSON_MODE; then
        printf '{"success":%s,"errors":[%s],"warnings":[%s],"session_status":"%s"}\n' \
            "$success" "$errors_json" "$warnings_json" "$session_status"
    else
        if [[ "$success" == "true" ]]; then
            success "Validation: PASSED"
            log "Session Status: $session_status"
            if [[ -n "$warnings_json" && "$warnings_json" != '""' ]]; then
                warn "Warnings detected. Please review."
            fi
        else
            error "Validation: FAILED"
        fi
    fi
}

# --- Main Logic ---

# Array to collect errors and warnings
ERRORS=()
WARNINGS=()
SESSION_STATUS="unknown"

# Get vault root
if [[ -z "$VAULT_ROOT" ]]; then
    VAULT_ROOT=$(detect_vault_root)
    if [[ $? -ne 0 ]]; then
        ERRORS+=("\"Could not detect vault root. Run from within vault or set VAULT_ROOT environment variable.\"")
    fi
fi

# Validate session path provided
if [[ -z "$SESSION_PATH" ]]; then
    ERRORS+=("\"Session path is required\"")
# Check if session directory exists only if path was provided
elif [[ ! -d "$SESSION_PATH" ]]; then
    ERRORS+=("\"Session directory does not exist: $SESSION_PATH\"")
    SESSION_STATUS="missing"
fi

# Proceed with file checks only if the session directory exists
if [[ -d "$SESSION_PATH" ]]; then
    log "Validating plan prerequisites for: $SESSION_PATH"

    # Define required files from SCOPE phase
    REQUIRED_FILES=(
        "learning-spec.md"
        "resources.md" 
        "learning-plan.md"
    )

    # Check each required file exists
    for file in "${REQUIRED_FILES[@]}"; do
        file_path="$SESSION_PATH/$file"
        if [[ ! -f "$file_path" ]]; then
            ERRORS+=("\"Missing required file: $file\"")
        else
            log "Found: $file"
            
            # Check file is not empty
            if [[ ! -s "$file_path" ]]; then
                ERRORS+=("\"Required file is empty: $file\"")
            fi
            
            # Check for remaining template placeholders
            if grep -q "{[A-Z_]*}" "$file_path" 2>/dev/null; then
                PLACEHOLDER_COUNT=$(grep -o "{[A-Z_]*}" "$file_path" | wc -l)
                ERRORS+=("\"File contains $PLACEHOLDER_COUNT unfilled template placeholders: $file\"")
            fi
        fi
    done

    # Check learning-plan.md status
    LEARNING_PLAN_PATH="$SESSION_PATH/learning-plan.md"
    if [[ -f "$LEARNING_PLAN_PATH" ]]; then
        # Check if already has plan content (not just basic template)
        if grep -q "Main Learning Phases" "$LEARNING_PLAN_PATH" && grep -q "<!-- Topics, objectives, resources, estimated duration -->" "$LEARNING_PLAN_PATH"; then
            SESSION_STATUS="scope_complete"
        elif grep -q "Main Learning Phases" "$LEARNING_PLAN_PATH" && ! grep -q "<!-- Topics, objectives, resources, estimated duration -->" "$LEARNING_PLAN_PATH"; then
            WARNINGS+=("\"Learning plan appears to already have plan content - may overwrite existing plan\"")
            SESSION_STATUS="plan_exists"
        else
            ERRORS+=("\"Learning plan format is unexpected - may be corrupted\"")
            SESSION_STATUS="corrupted"
        fi
    else
        SESSION_STATUS="missing_files"
    fi

    # Validate session is in correct directory plan
    if [[ "$SESSION_PATH" != *"/learn/"* ]]; then
        WARNINGS+=("\"Session is not in expected 'learn/' directory plan\"")
    fi
fi


# --- Final Output ---

# Format errors and warnings for JSON output
errors_json=$(IFS=,; echo "${ERRORS[*]}")
warnings_json=$(IFS=,; echo "${WARNINGS[*]}")

if [[ ${#ERRORS[@]} -eq 0 ]]; then
    output_result "true" "$errors_json" "$warnings_json" "$SESSION_STATUS"
else
    output_result "false" "$errors_json" "$warnings_json" "$SESSION_STATUS"
    # Now we print the errors for human-readable mode
    if ! $JSON_MODE; then
        for err in "${ERRORS[@]}"; do
            # Remove quotes for cleaner printing
            error "${err//\"/}"
        done
    fi
    exit 1
fi
