#!/bin/bash

# Learning Session Creation Script
# Creates a new learning session folder structure

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="${VAULT_ROOT:-}"
SESSION_BASE_DIR="learn"
JSON_MODE=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] \"Topic Name\""
            echo "Creates a new learning session structure"
            exit 0 
            ;;
        *) TOPIC_NAME="$arg" ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[LEARNING-INIT]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
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

# Get vault root
if [[ -z "$VAULT_ROOT" ]]; then
    VAULT_ROOT=$(detect_vault_root)
    if [[ $? -ne 0 ]]; then
        error "Could not detect vault root. Run from within vault or set VAULT_ROOT environment variable."
        exit 1
    fi
fi

# Function to output JSON results
output_result() {
    local success="$1"
    local session_path="$2"
    local session_name="$3"
    local files_created="$4"
    local error_msg="$5"
    
    if $JSON_MODE; then
        if [[ "$success" == "true" ]]; then
            printf '{"success":true,"session_path":"%s","session_name":"%s","files_created":[%s]}\n' \
                "$session_path" "$session_name" "$files_created"
        else
            printf '{"success":false,"error":"%s"}\n' "$error_msg"
        fi
    else
        if [[ "$success" == "true" ]]; then
            echo "Session Path: $session_path"
            echo "Session Name: $session_name"
            echo "Files Created: $files_created"
        else
            echo "Error: $error_msg"
        fi
    fi
}

# Validate input
if [[ -z "$TOPIC_NAME" ]]; then
    output_result "false" "" "" "" "Topic name is required"
    exit 1
fi
CURRENT_DATE=$(date +%Y-%m-%d)
SESSION_DIR_NAME="${CURRENT_DATE} ${TOPIC_NAME}"
SESSION_FULL_PATH="$VAULT_ROOT/$SESSION_BASE_DIR/$SESSION_DIR_NAME"

log "Creating learning session: $TOPIC_NAME"
log "Session directory: $SESSION_FULL_PATH"

# Check if session already exists
if [[ -d "$SESSION_FULL_PATH" ]]; then
    output_result "false" "" "" "" "Learning session already exists: $SESSION_DIR_NAME"
    exit 1
fi

# Create session directory structure
if ! $JSON_MODE; then
    log "Creating session directory structure..."
fi

mkdir -p "$SESSION_FULL_PATH"

# Validate session directory was created
if [[ ! -d "$SESSION_FULL_PATH" ]]; then
    output_result "false" "" "" "" "Failed to create session directory: $SESSION_FULL_PATH"
    exit 1
fi

# Success - return session information
FILES_CREATED='"learning-spec.md","resources.md","learning-plan.md"'

output_result "true" "$SESSION_FULL_PATH" "$SESSION_DIR_NAME" "$FILES_CREATED" ""

if ! $JSON_MODE; then
    success "Learning session directory created successfully!"
    log ""
    log "Session Location: $SESSION_FULL_PATH"
    log "Session Name: $SESSION_DIR_NAME"
    log ""
    log "Ready for interactive specification gathering!"
fi