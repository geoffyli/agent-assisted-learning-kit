#!/bin/bash

# Learning Session Creation Script
# Creates a new learning session folder structure

set -euo pipefail  # Strict error handling

# Configuration
VAULT_ROOT="${VAULT_ROOT:-}"
SESSION_BASE_DIR="learn"
JSON_MODE=false
TOPIC_NAME=""

# Function to safely escape JSON strings
escape_json_string() {
    local string="$1"
    printf '%s' "$string" | sed 's/\\/\\\\\\\\/g; s/"/\\\\"/g; s/\t/\\\\t/g; s/\r/\\\\r/g; s/\n/\\\\n/g'
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
                echo "Creates a new learning session structure"
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

# Colors for output (only in non-JSON mode)
if [[ "$JSON_MODE" != "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

log() {
    if [[ "$JSON_MODE" != "true" ]]; then
        echo -e "${BLUE}[LEARNING-INIT]${NC} $1"
    fi
}

warn() {
    if [[ "$JSON_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

error() {
    if [[ "$JSON_MODE" != "true" ]]; then
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

success() {
    if [[ "$JSON_MODE" != "true" ]]; then
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

# Function to output JSON results safely
output_result() {
    local success="$1"
    local session_path="$2"
    local session_name="$3"
    local created_directory="$4"
    local error_msg="$5"
    
    if [[ "$JSON_MODE" == "true" ]]; then
        if [[ "$success" == "true" ]]; then
            printf '{"success":true,"session_path":"%s","session_name":"%s","created_directory":"%s"}\n' \
                "$(escape_json_string "$session_path")" \
                "$(escape_json_string "$session_name")" \
                "$(escape_json_string "$created_directory")"
        else
            printf '{"success":false,"error":"%s"}\n' "$(escape_json_string "$error_msg")"
        fi
    else
        if [[ "$success" == "true" ]]; then
            echo "Session Path: $session_path"
            echo "Session Name: $session_name"
            echo "Created Directory: $created_directory"
        else
            echo "Error: $error_msg"
        fi
    fi
}

# Function to validate topic name
validate_topic_name() {
    local topic="$1"
    
    # Check if provided
    if [[ -z "$topic" ]]; then
        output_result "false" "" "" "" "Topic name is required"
        exit 1
    fi
    
    # Check length
    local length=${#topic}
    if [[ $length -lt 3 ]]; then
        output_result "false" "" "" "" "Topic name too short. Please provide a more descriptive topic (minimum 3 characters)"
        exit 1
    elif [[ $length -gt 50 ]]; then
        output_result "false" "" "" "" "Topic name too long ($length characters). Please keep under 50 characters for better organization"
        exit 1
    fi
    
    # Check for invalid characters using case statement
    local i char
    for (( i=0; i<${#topic}; i++ )); do
        char="${topic:$i:1}"
        case "$char" in
            '/'|'\'|':'|'*'|'?'|'"'|"'"|'<'|'>'|'|')
                output_result "false" "" "" "" "Topic name contains invalid characters. Avoid: / \\ : * ? \" ' < > |"
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Validate topic name
    validate_topic_name "$TOPIC_NAME"
    
    # Get vault root
    if [[ -z "$VAULT_ROOT" ]]; then
        if ! VAULT_ROOT=$(detect_vault_root); then
            output_result "false" "" "" "" "Could not detect vault root. Run from within vault or set VAULT_ROOT environment variable."
            exit 1
        fi
    fi
    
    # Prepare session information
    local current_date session_dir_name session_full_path
    current_date=$(date +%Y-%m-%d)
    session_dir_name="${current_date} ${TOPIC_NAME}"
    session_full_path="$VAULT_ROOT/$SESSION_BASE_DIR/$session_dir_name"
    
    log "Creating learning session: $TOPIC_NAME"
    log "Session directory: $session_full_path"
    
    # Check if session already exists
    if [[ -d "$session_full_path" ]]; then
        output_result "false" "" "" "" "Learning session already exists: $session_dir_name"
        exit 1
    fi
    
    # Ensure parent directory exists
    local session_parent_dir="$VAULT_ROOT/$SESSION_BASE_DIR"
    if [[ ! -d "$session_parent_dir" ]]; then
        log "Creating learn directory: $session_parent_dir"
        if ! mkdir -p "$session_parent_dir" 2>/dev/null; then
            output_result "false" "" "" "" "Failed to create learn directory: $session_parent_dir"
            exit 1
        fi
    fi
    
    # Create session directory structure
    log "Creating session directory structure..."
    
    if ! mkdir -p "$session_full_path" 2>/dev/null; then
        output_result "false" "" "" "" "Failed to create session directory: $session_full_path"
        exit 1
    fi
    
    # Create Resources subdirectory
    if ! mkdir -p "$session_full_path/Resources" 2>/dev/null; then
        output_result "false" "" "" "" "Failed to create Resources directory: $session_full_path/Resources"
        exit 1
    fi
    
    # Validate session directory was created
    if [[ ! -d "$session_full_path" ]]; then
        output_result "false" "" "" "" "Session directory creation verification failed: $session_full_path"
        exit 1
    fi
    
    # Copy and clean learning templates
    log "Copying learning templates..."
    local script_dir templates_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    templates_dir="$script_dir/../templates"
    
    if [[ -d "$templates_dir" ]]; then
        # Function to remove frontmatter from template file
        clean_template() {
            local source_file="$1"
            local dest_file="$2"
            
            # Skip frontmatter (lines between --- markers) and copy rest
            awk '
                BEGIN { in_frontmatter = 0; frontmatter_ended = 0 }
                /^---$/ { 
                    if (!frontmatter_ended) {
                        in_frontmatter = !in_frontmatter
                        if (!in_frontmatter) frontmatter_ended = 1
                        next
                    }
                }
                !in_frontmatter && frontmatter_ended { print }
            ' "$source_file" > "$dest_file"
        }
        
        # Copy and clean each template with proper naming
        # Map template files to final names without -template suffix
        
        for template in "$templates_dir"/*.md; do
            if [[ -f "$template" ]]; then
                local template_basename final_name
                template_basename="$(basename "$template")"
                
                # Map template names to final names
                case "$template_basename" in
                    "learning-spec-template.md")
                        final_name="learning-spec.md"
                        ;;
                    "learning-plan-template.md")
                        final_name="learning-plan.md"
                        ;;
                    "resources-template.md")
                        final_name="resources.md"
                        ;;
                    *)
                        final_name=""
                        ;;
                esac
                
                if [[ -n "$final_name" ]]; then
                    clean_template "$template" "$session_full_path/$final_name"
                    log "Copied and cleaned: $template_basename → $final_name"
                fi
            fi
        done
    else
        warn "Templates directory not found: $templates_dir"
        warn "Session created without template files"
    fi
    
    # Success - return session information
    output_result "true" "$session_full_path" "$session_dir_name" "$session_full_path" ""
    
    success "Learning session directory created successfully!"
    log ""
    log "Session Location: $session_full_path"
    log "Session Name: $session_dir_name"
    log ""
    log "Ready for interactive specification gathering!"
}

# Execute main function with all arguments
main "$@"