#!/bin/bash

# Study Phase Prerequisites Validation Script
# Validates that PLAN phase is complete and ready for STUDY phase

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
            echo "Validates that PLAN phase is complete for study phase"
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
        echo -e "${BLUE}[STUDY-PREREQ]${NC} $1"
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

# Function to analyze learning plan progress
analyze_progress() {
    local learning_plan_path="$1"
    local total_phases=0
    local completed_phases=0
    local current_phase=""
    local in_progress_phase=""
    
    # Count learning phases and analyze checkbox completion
    while IFS= read -r line; do
        if [[ "$line" =~ ^###[[:space:]]+Learning[[:space:]]+Phase[[:space:]]+([0-9]+): ]]; then
            ((total_phases++))
            local phase_num="${BASH_REMATCH[1]}"
            local phase_name=$(echo "$line" | sed 's/^### Learning Phase [0-9]*: //')
            
            # Check if this phase has completed checkpoints
            local phase_complete=true
            local has_checkpoints=false
            
            # Read ahead to find checkpoints for this phase
            local temp_file=$(mktemp)
            tail -n +$(($(grep -n "^### Learning Phase $phase_num:" "$learning_plan_path" | cut -d: -f1) + 1)) "$learning_plan_path" | \
                head -n 50 > "$temp_file"
            
            while IFS= read -r checkpoint_line; do
                if [[ "$checkpoint_line" =~ ^###[[:space:]]+Learning[[:space:]]+Phase ]]; then
                    break  # Next phase found
                fi
                if [[ "$checkpoint_line" =~ ^-[[:space:]]+\[[[:space:]]*\] ]]; then
                    has_checkpoints=true
                    phase_complete=false
                elif [[ "$checkpoint_line" =~ ^-[[:space:]]+\[x\] ]] || [[ "$checkpoint_line" =~ ^-[[:space:]]+\[X\] ]]; then
                    has_checkpoints=true
                fi
            done < "$temp_file"
            rm "$temp_file"
            
            if [[ "$has_checkpoints" == "true" ]]; then
                if [[ "$phase_complete" == "true" ]]; then
                    ((completed_phases++))
                elif [[ -z "$in_progress_phase" ]]; then
                    in_progress_phase="$phase_num"
                    current_phase="Phase $phase_num: $phase_name"
                fi
            fi
        fi
    done < "$learning_plan_path"
    
    # If no in-progress phase found, next phase is current
    if [[ -z "$current_phase" && $completed_phases -lt $total_phases ]]; then
        current_phase="Phase $((completed_phases + 1))"
    elif [[ $completed_phases -eq $total_phases ]]; then
        current_phase="All phases complete"
    fi
    
    echo "$total_phases,$completed_phases,$current_phase"
}

# Function to output JSON results
output_result() {
    local success="$1"
    local errors_json="$2"
    local warnings_json="$3"
    local current_phase="$4"
    local progress_state="$5"
    
    if $JSON_MODE; then
        printf '{"success":%s,"errors":[%s],"warnings":[%s],"current_phase":"%s","progress_state":"%s"}\n' \
            "$success" "$errors_json" "$warnings_json" "$current_phase" "$progress_state"
    else
        if [[ "$success" == "true" ]]; then
            success "Validation: PASSED"
            log "Current Phase: $current_phase"
            log "Progress State: $progress_state"
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
CURRENT_PHASE="unknown"
PROGRESS_STATE="unknown"

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
fi

# Proceed with validation only if session directory exists
if [[ -d "$SESSION_PATH" ]]; then
    log "Validating study prerequisites for: $SESSION_PATH"

    # Define required files from PLAN phase
    REQUIRED_FILES=(
        "learning-spec.md"
        "resources.md" 
        "learning-plan.md"
    )

    # Check each required file exists and is populated
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
        fi
    done

    # Validate learning-plan.md is fully developed
    LEARNING_PLAN_PATH="$SESSION_PATH/learning-plan.md"
    if [[ -f "$LEARNING_PLAN_PATH" ]]; then
        # Check for learning phases
        if ! grep -q "^### Learning Phase [0-9]*:" "$LEARNING_PLAN_PATH"; then
            ERRORS+=("\"Learning plan does not contain populated learning phases\"")
        else
            # Check that phases have required sections
            local phases_count=$(grep -c "^### Learning Phase [0-9]*:" "$LEARNING_PLAN_PATH")
            local contents_count=$(grep -c "^#### Contents" "$LEARNING_PLAN_PATH")
            local resources_count=$(grep -c "^#### Resources" "$LEARNING_PLAN_PATH")
            local checkpoints_count=$(grep -c "^#### Checkpoints" "$LEARNING_PLAN_PATH")
            local vault_count=$(grep -c "^#### Knowledge Vault Integration" "$LEARNING_PLAN_PATH")
            
            if [[ $contents_count -lt $phases_count ]]; then
                ERRORS+=("\"Learning phases missing Contents sections\"")
            fi
            if [[ $resources_count -lt $phases_count ]]; then
                ERRORS+=("\"Learning phases missing Resources sections\"")
            fi
            if [[ $checkpoints_count -lt $phases_count ]]; then
                ERRORS+=("\"Learning phases missing Checkpoints sections\"")
            fi
            if [[ $vault_count -lt $phases_count ]]; then
                ERRORS+=("\"Learning phases missing Knowledge Vault Integration sections\"")
            fi
            
            # Analyze progress if structure is valid
            if [[ ${#ERRORS[@]} -eq 0 ]]; then
                local progress_result=$(analyze_progress "$LEARNING_PLAN_PATH")
                local total_phases=$(echo "$progress_result" | cut -d, -f1)
                local completed_phases=$(echo "$progress_result" | cut -d, -f2)
                local current_phase=$(echo "$progress_result" | cut -d, -f3)
                
                CURRENT_PHASE="$current_phase"
                PROGRESS_STATE="$completed_phases/$total_phases phases complete"
                
                log "Found $total_phases learning phases"
                log "Progress: $completed_phases/$total_phases phases complete"
                log "Current phase: $current_phase"
            fi
        fi
        
        # Check for template placeholders that shouldn't exist
        if grep -q "{[A-Z_]*}" "$LEARNING_PLAN_PATH" 2>/dev/null; then
            PLACEHOLDER_COUNT=$(grep -o "{[A-Z_]*}" "$LEARNING_PLAN_PATH" | wc -l)
            ERRORS+=("\"Learning plan contains $PLACEHOLDER_COUNT unfilled template placeholders\"")
        fi
    fi

    # Validate vault structure for note creation
    if [[ -n "$VAULT_ROOT" ]]; then
        if [[ ! -f "$VAULT_ROOT/AGENTS.md" ]]; then
            WARNINGS+=("\"AGENTS.md not found - note creation may not follow vault standards\"")
        fi
        
        if [[ ! -d "$VAULT_ROOT/docs" ]]; then
            ERRORS+=("\"Vault docs/ directory not found - cannot create notes\"")
        fi
    fi

    # Validate session is in correct directory structure
    if [[ "$SESSION_PATH" != *"/learn/"* ]]; then
        WARNINGS+=("\"Session is not in expected 'learn/' directory structure\"")
    fi
fi

# --- Final Output ---

# Format errors and warnings for JSON output
errors_json=$(IFS=,; echo "${ERRORS[*]}")
warnings_json=$(IFS=,; echo "${WARNINGS[*]}")

if [[ ${#ERRORS[@]} -eq 0 ]]; then
    output_result "true" "$errors_json" "$warnings_json" "$CURRENT_PHASE" "$PROGRESS_STATE"
else
    output_result "false" "$errors_json" "$warnings_json" "$CURRENT_PHASE" "$PROGRESS_STATE"
    # Print errors for human-readable mode
    if ! $JSON_MODE; then
        for err in "${ERRORS[@]}"; do
            # Remove quotes for cleaner printing
            error "${err//\"/}"
        done
    fi
    exit 1
fi