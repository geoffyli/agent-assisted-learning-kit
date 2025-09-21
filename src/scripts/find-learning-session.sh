#!/bin/bash

# Learning Session Discovery Script
# Finds learning sessions by identifier and handles disambiguation

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="${VAULT_ROOT:-}"
JSON_MODE=false
SESSION_IDENTIFIER=""

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] \"SESSION_IDENTIFIER\""
            echo "Finds learning sessions by identifier (full path, session name, topic name, or partial match)"
            echo "Returns session path and details, or disambiguation options"
            exit 0 
            ;;
        *) SESSION_IDENTIFIER="$arg" ;;
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
        echo -e "${BLUE}[SESSION-FINDER]${NC} $1"
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

# Function to list all available sessions
list_all_sessions() {
    local learn_dir="$1"
    local sessions=()
    
    if [[ -d "$learn_dir" ]]; then
        while IFS= read -r -d '' session_dir; do
            local session_name=$(basename "$session_dir")
            local session_status="Unknown"
            
            # Check session status
            if [[ -f "$session_dir/learning-plan.md" ]]; then
                if grep -q "^### Learning Phase [0-9]*:" "$session_dir/learning-plan.md" 2>/dev/null; then
                    session_status="Ready for Study"
                else
                    session_status="Plan Incomplete"
                fi
            elif [[ -f "$session_dir/learning-spec.md" ]]; then
                session_status="Ready for Plan"
            else
                session_status="Incomplete"
            fi
            
            sessions+=("\"$session_name\":\"$session_status\"")
        done < <(find "$learn_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    fi
    
    echo "${sessions[@]}"
}

# Function to search for sessions by identifier
search_sessions() {
    local learn_dir="$1"
    local identifier="$2"
    local matches=()
    
    if [[ ! -d "$learn_dir" ]]; then
        echo ""
        return
    fi
    
    # Search for sessions
    while IFS= read -r -d '' session_dir; do
        local session_name=$(basename "$session_dir")
        local session_path="$session_dir"
        
        # Check various match criteria
        local match=false
        
        # 1. Exact full path match
        if [[ "$session_path" == "$identifier" ]]; then
            match=true
        # 2. Exact session name match
        elif [[ "$session_name" == "$identifier" ]]; then
            match=true
        # 3. Topic name match (remove date prefix)
        elif [[ "$session_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+(.*)$ ]]; then
            local topic_name="${BASH_REMATCH[1]}"
            if [[ "$topic_name" == "$identifier" ]]; then
                match=true
            fi
        # 4. Partial match (case-insensitive)
        elif [[ "${session_name,,}" == *"${identifier,,}"* ]]; then
            match=true
        fi
        
        if [[ "$match" == true ]]; then
            # Check if session has learning-plan.md for study readiness
            local status="incomplete"
            if [[ -f "$session_path/learning-plan.md" ]]; then
                if grep -q "^### Learning Phase [0-9]*:" "$session_path/learning-plan.md" 2>/dev/null; then
                    status="ready"
                else
                    status="plan_incomplete"
                fi
            fi
            
            matches+=("$session_path:$session_name:$status")
        fi
    done < <(find "$learn_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    
    echo "${matches[@]}"
}

# Function to output JSON results
output_result() {
    local success="$1"
    local session_path="$2"
    local session_name="$3"
    local status="$4"
    local matches_json="$5"
    local available_sessions_json="$6"
    local error_msg="$7"
    
    if $JSON_MODE; then
        if [[ "$success" == "true" ]]; then
            printf '{"success":true,"session_path":"%s","session_name":"%s","status":"%s"}\n' \
                "$session_path" "$session_name" "$status"
        elif [[ "$success" == "disambiguation" ]]; then
            printf '{"success":false,"disambiguation_needed":true,"matches":{%s},"available_sessions":{%s}}\n' \
                "$matches_json" "$available_sessions_json"
        else
            printf '{"success":false,"error":"%s","available_sessions":{%s}}\n' \
                "$error_msg" "$available_sessions_json"
        fi
    else
        if [[ "$success" == "true" ]]; then
            success "Found session: $session_name"
            log "Path: $session_path"
            log "Status: $status"
        elif [[ "$success" == "disambiguation" ]]; then
            warn "Multiple sessions match '$SESSION_IDENTIFIER':"
            echo "$matches_json" | tr ',' '\n' | sed 's/"//g' | sed 's/:/: /'
        else
            error "$error_msg"
            if [[ -n "$available_sessions_json" ]]; then
                log "Available sessions:"
                echo "$available_sessions_json" | tr ',' '\n' | sed 's/"//g' | sed 's/:/: /'
            fi
        fi
    fi
}

# --- Main Logic ---

# Get vault root
if [[ -z "$VAULT_ROOT" ]]; then
    VAULT_ROOT=$(detect_vault_root)
    if [[ $? -ne 0 ]]; then
        output_result "false" "" "" "" "" "" "Could not detect vault root. Run from within vault or set VAULT_ROOT environment variable."
        exit 1
    fi
fi

LEARN_DIR="$VAULT_ROOT/learn"

# If no identifier provided, list all available sessions
if [[ -z "$SESSION_IDENTIFIER" ]]; then
    available_sessions=$(list_all_sessions "$LEARN_DIR")
    if [[ -z "$available_sessions" ]]; then
        output_result "false" "" "" "" "" "" "No learning sessions found in $LEARN_DIR"
    else
        output_result "false" "" "" "" "" "$available_sessions" "No session identifier provided. Please specify which session to study."
    fi
    exit 1
fi

# Search for matching sessions
log "Searching for sessions matching: $SESSION_IDENTIFIER"
matches=($(search_sessions "$LEARN_DIR" "$SESSION_IDENTIFIER"))

# Get available sessions for error/disambiguation output
available_sessions=$(list_all_sessions "$LEARN_DIR")

if [[ ${#matches[@]} -eq 0 ]]; then
    # No matches found
    output_result "false" "" "" "" "" "$available_sessions" "No sessions found matching '$SESSION_IDENTIFIER'"
    exit 1
elif [[ ${#matches[@]} -eq 1 ]]; then
    # Single match found
    match="${matches[0]}"
    session_path=$(echo "$match" | cut -d: -f1)
    session_name=$(echo "$match" | cut -d: -f2)
    status=$(echo "$match" | cut -d: -f3)
    
    if [[ "$status" != "ready" ]]; then
        if [[ "$status" == "plan_incomplete" ]]; then
            output_result "false" "" "" "" "" "$available_sessions" "Session '$session_name' found but PLAN phase is incomplete. Run learning-plan command first."
        else
            output_result "false" "" "" "" "" "$available_sessions" "Session '$session_name' found but is not ready for study. Complete SCOPE and PLAN phases first."
        fi
        exit 1
    fi
    
    output_result "true" "$session_path" "$session_name" "$status" "" "" ""
else
    # Multiple matches - need disambiguation
    matches_json=""
    for match in "${matches[@]}"; do
        session_path=$(echo "$match" | cut -d: -f1)
        session_name=$(echo "$match" | cut -d: -f2)
        status=$(echo "$match" | cut -d: -f3)
        
        if [[ -n "$matches_json" ]]; then
            matches_json+=","
        fi
        matches_json+="\"$session_name\":\"$status\""
    done
    
    output_result "disambiguation" "" "" "" "$matches_json" "$available_sessions" ""
    exit 1
fi