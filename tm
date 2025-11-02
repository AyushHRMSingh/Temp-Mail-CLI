#!/bin/bash

# Mail.tm CLI Tool
# A minimal, modular CLI for managing temporary email accounts using Mail.tm API

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the config file
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/db.sh"

# Discover available commands
get_available_commands() {
    if [[ -d "$SCRIPT_DIR/commands" ]]; then
        for file in "$SCRIPT_DIR/commands"/*; do
            if [[ -x "$file" && -f "$file" ]]; then
                basename "$file"
            fi
        done | sort
    fi
}

# Check if command exists
command_exists() {
    local cmd="$1"
    [[ -x "$SCRIPT_DIR/commands/$cmd" ]]
}

# Execute a command
execute_command() {
    local cmd="$1"
    shift
    
    if command_exists "$cmd"; then
        exec "$SCRIPT_DIR/commands/$cmd" "$@"
    else
        return 1
    fi
}

# Show main help
show_help() {
    echo "Mail.tm CLI - Temporary Email Management Tool"
    echo ""
    echo "A modular CLI for managing temporary email accounts using Mail.tm API"
    echo ""
    echo "Usage: tm <command> [options]"
    echo ""
    echo "Commands:"
    echo "  create <name> [password]    Create account"
    echo "  list                        List accounts" 
    echo "  mail <name>                 Show emails"
    echo "  read <name> <number>        Read email"
    echo "  monitor <name>              Watch for new mail"
    echo "  delete <name>               Delete account"
    echo ""
    echo "Examples:"
    echo "  tm create work mypass123    # Create with password"
    echo "  tm create test              # Create with generated password"
    echo "  tm mail work                # Show emails"
    echo "  tm read work 1              # Read first email"
    echo "  tm monitor work             # Watch for new emails"
}

# Main function
main() {
    # Initialize database
    db_init
    
    # Check basic dependencies
    local missing_deps=()
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "On macOS: brew install ${missing_deps[*]}"
        echo "On Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
    
    local command="${1:-help}"
    
    # Handle special cases
    case "$command" in
        help|--help|-h)
            show_help
            exit 0
            ;;
        version|--version|-v)
            echo "Mail.tm CLI v1.0"
            exit 0
            ;;
    esac
    
    # Try to execute the command
    if command_exists "$command"; then
        shift
        execute_command "$command" "$@"
    else
        print_error "Unknown command: $command"
        echo ""
        show_help
        exit 1
    fi
}

# Run main function with all arguments
main "$@"