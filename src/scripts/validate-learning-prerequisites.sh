#!/bin/bash

# Learning Prerequisites Validation Script
# Validates system state before creating a learning session

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_MODE=false
TOPIC_NAME=""

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] \"Topic Name\""
            echo "Validates prerequisites for creating a learning session"
            exit 0 
            ;;
        *) TOPIC_NAME="$arg" ;;
    esac
done

# Function to output results
output_result() {
    local success="$1"
    local errors="$2"
    local warnings="$3"
    local current_path="$4"
    
    if $JSON_MODE; then
        printf '{"success":%s,"errors":[%s],"warnings":[%s],"current_path":"%s"}\n' \
            "$success" "$errors" "$warnings" "$current_path"
    else
        echo "Success: $success"
        [ -n "$errors" ] && echo "Errors: $errors"
        [ -n "$warnings" ] && echo "Warnings: $warnings"
        [ -n "$current_path" ] && echo "Current Path: $current_path"
    fi
}

# Function to detect vault root
detect_vault_root() {
    local current_dir="$PWD"
    
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/AGENTS.md" && -d "$current_dir/docs" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    return 1
}

# Validation variables
ERRORS=()
WARNINGS=()
VAULT_ROOT=""

# Validate topic name provided
if [[ -z "$TOPIC_NAME" ]]; then
    ERRORS+=("\"Topic name is required\"")
fi

# Detect vault root
VAULT_ROOT=$(detect_vault_root)
if [[ $? -ne 0 ]]; then
    ERRORS+=("\"Could not detect vault root. Ensure you are running from within the vault directory\"")
else
    # Check required directories exist
    SESSION_BASE_DIR="$VAULT_ROOT/learn"
    
    if [[ ! -d "$VAULT_ROOT/docs" ]]; then
        ERRORS+=("\"Vault docs/ directory not found\"")
    fi
    
    # Create learn directory if it doesn't exist
    if [[ ! -d "$SESSION_BASE_DIR" ]]; then
        mkdir -p "$SESSION_BASE_DIR" 2>/dev/null || ERRORS+=("\"Could not create learn/ directory\"")
    fi
fi

# Check if topic name is reasonable
if [[ -n "$TOPIC_NAME" ]]; then
    # Check length
    if [[ ${#TOPIC_NAME} -lt 3 ]]; then
        ERRORS+=("\"Topic name too short. Please provide a more descriptive topic (minimum 3 characters)\"")
    elif [[ ${#TOPIC_NAME} -gt 50 ]]; then
        WARNINGS+=("\"Topic name is quite long (${#TOPIC_NAME} characters). Consider shortening for better organization\"")
    fi
    
    # Check for invalid characters
    if [[ "$TOPIC_NAME" =~ [/\\:*?\"<>|] ]]; then
        ERRORS+=("\"Topic name contains invalid characters. Avoid: / \\\\ : * ? \\\" < > |\"")
    fi
    
    # Check if session already exists
    if [[ -n "$VAULT_ROOT" ]]; then
        CURRENT_DATE=$(date +%Y-%m-%d)
        SESSION_DIR_NAME="${CURRENT_DATE} ${TOPIC_NAME}"
        SESSION_FULL_PATH="$VAULT_ROOT/learn/$SESSION_DIR_NAME"
        
        if [[ -d "$SESSION_FULL_PATH" ]]; then
            ERRORS+=("\"Learning session already exists: $SESSION_DIR_NAME\"")
        fi
        
        # Check for similar existing sessions
        SIMILAR_SESSIONS=$(find "$VAULT_ROOT/learn" -type d -name "*$TOPIC_NAME*" 2>/dev/null | head -3)
        if [[ -n "$SIMILAR_SESSIONS" ]]; then
            WARNINGS+=("\"Similar learning sessions found. Consider if this is a duplicate or continuation\"")
        fi
    fi
fi

# Validate vault structure follows AGENTS.md standards
if [[ -n "$VAULT_ROOT" && -f "$VAULT_ROOT/AGENTS.md" ]]; then
    # Check if Management MOC exists
    if [[ ! -f "$VAULT_ROOT/docs/Management/Management MOC.md" ]]; then
        WARNINGS+=("\"Management MOC not found. Learning Sessions Index will be created without proper parent\"")
    fi
fi

# Format error and warning arrays for JSON
ERRORS_JSON=$(printf '"%s",' "${ERRORS[@]}")
ERRORS_JSON="${ERRORS_JSON%,}"  # Remove trailing comma

WARNINGS_JSON=$(printf '"%s",' "${WARNINGS[@]}")
WARNINGS_JSON="${WARNINGS_JSON%,}"  # Remove trailing comma

# Determine success
SUCCESS="true"
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    SUCCESS="false"
fi

# Output result
output_result "$SUCCESS" "$ERRORS_JSON" "$WARNINGS_JSON" "$PWD"

# Exit with appropriate code
if [[ "$SUCCESS" == "false" ]]; then
    exit 1
else
    exit 0
fi