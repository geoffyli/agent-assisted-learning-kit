#!/bin/bash

# Learning Init Prerequisites Validation Script
# Validates system state before creating a learning session

set -euo pipefail  # Strict error handling

# Configuration
JSON_MODE=false
TOPIC_NAME=""

# Function to safely escape JSON strings
escape_json_string() {
    local string="$1"
    # Escape backslashes, quotes, and control characters
    printf '%s' "$string" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g'
}

# Function to build JSON array safely
build_json_array() {
    local array_name="$1"
    local json_array=""
    local first=true
    
    # Use eval to access array indirectly (compatible with older bash)
    eval "local array_size=\${#${array_name}[@]}"
    
    # Handle empty arrays
    if [[ $array_size -eq 0 ]]; then
        echo ""
        return
    fi
    
    eval "local array_items=(\"\${${array_name}[@]}\")"
    
    for item in "${array_items[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            json_array+=","
        fi
        json_array+="\"$(escape_json_string "$item")\""
    done
    
    echo "$json_array"
}

# Parse arguments properly
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json)
                JSON_MODE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--json] \"Topic Name\""
                echo "Validates prerequisites for creating a learning session"
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Error: Unknown flag $1" >&2
                exit 1
                ;;
            *)
                if [[ -n "$TOPIC_NAME" ]]; then
                    echo "Error: Multiple topic names provided: '$TOPIC_NAME' and '$1'" >&2
                    exit 1
                fi
                TOPIC_NAME="$1"
                shift
                ;;
        esac
    done
    
    # Handle remaining positional arguments
    if [[ $# -gt 0 ]]; then
        if [[ -n "$TOPIC_NAME" ]]; then
            echo "Error: Multiple topic names provided" >&2
            exit 1
        fi
        TOPIC_NAME="$1"
        shift
        
        if [[ $# -gt 0 ]]; then
            echo "Error: Too many arguments provided" >&2
            exit 1
        fi
    fi
}

# Function to output results safely
output_result() {
    local success="$1"
    local errors_array_name="$2"
    local warnings_array_name="$3"
    local current_path="$4"
    
    if [[ "$JSON_MODE" == "true" ]]; then
        local errors_json warnings_json
        errors_json=$(build_json_array "$errors_array_name")
        warnings_json=$(build_json_array "$warnings_array_name")
        
        printf '{"success":%s,"errors":[%s],"warnings":[%s],"current_path":"%s"}\n' \
            "$success" "$errors_json" "$warnings_json" "$(escape_json_string "$current_path")"
    else
        echo "Success: $success"
        
        # Output errors
        eval "local error_count=\${#${errors_array_name}[@]}"
        if [[ $error_count -gt 0 ]]; then
            echo "Errors:"
            eval "local error_items=(\"\${${errors_array_name}[@]}\")"
            printf '  - %s\n' "${error_items[@]}"
        fi
        
        # Output warnings
        eval "local warning_count=\${#${warnings_array_name}[@]}"
        if [[ $warning_count -gt 0 ]]; then
            echo "Warnings:"
            eval "local warning_items=(\"\${${warnings_array_name}[@]}\")"
            printf '  - %s\n' "${warning_items[@]}"
        fi
        
        [[ -n "$current_path" ]] && echo "Current Path: $current_path"
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

# Function to validate topic name
validate_topic_name() {
    local topic="$1"
    local errors_array_name="$2"
    local warnings_array_name="$3"
    
    # Check if provided
    if [[ -z "$topic" ]]; then
        eval "${errors_array_name}+=(\"Topic name is required\")"
        return
    fi
    
    # Check length
    local length=${#topic}
    if [[ $length -lt 3 ]]; then
        eval "${errors_array_name}+=(\"Topic name too short. Please provide a more descriptive topic (minimum 3 characters)\")"
    elif [[ $length -gt 50 ]]; then
        eval "${warnings_array_name}+=(\"Topic name is quite long ($length characters). Consider shortening for better organization\")"
    fi
    
    # Check for invalid characters using case statement (more portable)
    local i char
    for (( i=0; i<${#topic}; i++ )); do
        char="${topic:$i:1}"
        case "$char" in
            '/'|'\'|':'|'*'|'?'|'"'|"'"|'<'|'>'|'|')
                eval "${errors_array_name}+=(\"Topic name contains invalid characters. Avoid: / \\\\ : * ? \\\" ' < > |\")"
                break
                ;;
        esac
    done
}

# Function to check session conflicts
check_session_conflicts() {
    local vault_root="$1"
    local topic="$2"
    local errors_array_name="$3"
    local warnings_array_name="$4"
    
    [[ -z "$vault_root" || -z "$topic" ]] && return
    
    local current_date session_dir_name session_full_path
    current_date=$(date +%Y-%m-%d)
    session_dir_name="${current_date} ${topic}"
    session_full_path="$vault_root/learn/$session_dir_name"
    
    # Check exact session exists
    if [[ -d "$session_full_path" ]]; then
        eval "${errors_array_name}+=(\"Learning session already exists: $session_dir_name\")"
        return
    fi
    
    # Check for similar sessions (safely)
    local learn_dir="$vault_root/learn"
    if [[ -d "$learn_dir" ]]; then
        local similar_count=0
        while IFS= read -r -d '' session_path; do
            local session_name
            session_name=$(basename "$session_path")
            if [[ "$session_name" == *"$topic"* ]]; then
                ((similar_count++))
                [[ $similar_count -ge 3 ]] && break
            fi
        done < <(find "$learn_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
        
        if [[ $similar_count -gt 0 ]]; then
            eval "${warnings_array_name}+=(\"Similar learning sessions found. Consider if this is a duplicate or continuation\")"
        fi
    fi
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize validation arrays
    local errors=()
    local warnings=()
    local vault_root=""
    
    # Validate topic name
    validate_topic_name "$TOPIC_NAME" errors warnings
    
    # Detect vault root
    if ! vault_root=$(detect_vault_root); then
        errors+=("Could not detect vault root. Ensure you are running from within the vault directory")
    else
        # Validate vault structure
        if [[ ! -d "$vault_root/docs" ]]; then
            errors+=("Vault docs/ directory not found")
        fi
        
        # Ensure learn directory exists (atomic operation)
        local session_base_dir="$vault_root/learn"
        if [[ ! -d "$session_base_dir" ]]; then
            if ! mkdir -p "$session_base_dir" 2>/dev/null; then
                errors+=("Could not create learn/ directory")
            fi
        fi
        
        # Check for session conflicts
        check_session_conflicts "$vault_root" "$TOPIC_NAME" errors warnings
        
        # Check agent system availability
        if [[ ! -d "$vault_root/.agent" ]]; then
            warnings+=(".agent/ directory not found in vault root. Some functionalities may be limited")
        fi
    fi
    
    # Determine success
    local success="true"
    if [[ ${#errors[@]} -gt 0 ]]; then
        success="false"
    fi
    
    # Output results
    output_result "$success" errors warnings "$PWD"
    
    # Exit with appropriate code
    if [[ "$success" == "false" ]]; then
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"