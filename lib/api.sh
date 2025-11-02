#!/bin/bash
# API functions for Mail.tm CLI
# Handles all interactions with the Mail.tm API

source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"

# Fetch available domains
api_get_domains() {
    local page=${1:-1}
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        "$API_BASE_URL/domains?page=$page"
}

# Create account on Mail.tm
api_create_account() {
    local address="$1"
    local password="$2"
    
    local payload=$(jq -n \
        --arg address "$address" \
        --arg password "$password" \
        '{address: $address, password: $password}')
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$API_BASE_URL/accounts"
}

# Get authentication token
api_get_token() {
    local address="$1"
    local password="$2"
    
    local payload=$(jq -n \
        --arg address "$address" \
        --arg password "$password" \
        '{address: $address, password: $password}')
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$API_BASE_URL/token"
}

# Get messages for account
api_get_messages() {
    local token="$1"
    local page=${2:-1}
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -H "Authorization: Bearer $token" \
        "$API_BASE_URL/messages?page=$page"
}

# Get specific message by ID
api_get_message() {
    local token="$1"
    local message_id="$2"
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -H "Authorization: Bearer $token" \
        "$API_BASE_URL/messages/$message_id"
}

# Delete message
api_delete_message() {
    local token="$1"
    local message_id="$2"
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -X DELETE \
        -H "Authorization: Bearer $token" \
        "$API_BASE_URL/messages/$message_id"
}

# Mark message as read
api_mark_message_read() {
    local token="$1"
    local message_id="$2"
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -X PATCH \
        -H "Authorization: Bearer $token" \
        "$API_BASE_URL/messages/$message_id"
}

# Get account info
api_get_account_info() {
    local token="$1"
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -H "Authorization: Bearer $token" \
        "$API_BASE_URL/me"
}

# Delete account from Mail.tm
api_delete_account() {
    local token="$1"
    local account_id="$2"
    
    curl -s --max-time "$REQUEST_TIMEOUT" \
        -X DELETE \
        -H "Authorization: Bearer $token" \
        "$API_BASE_URL/accounts/$account_id"
}

# Utility: Extract JSON field
api_json_get() {
    local json="$1"
    local field="$2"
    local default="${3:-}"
    
    echo "$json" | jq -r ".$field // \"$default\""
}

# Utility: Check if API response is successful
api_is_success() {
    local response="$1"
    
    # Check if response contains an id field (usually indicates success)
    local id=$(api_json_get "$response" "id")
    [[ -n "$id" && "$id" != "null" ]]
}

# Utility: Get error message from API response
api_get_error() {
    local response="$1"
    
    local error=$(api_json_get "$response" "detail" "Unknown error")
    echo "$error"
}

# Utility: Generate random password
api_generate_password() {
    local length=${1:-12}
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length}
}

# Utility: Validate email format
api_validate_email() {
    local email="$1"
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# Utility: Extract domain from email
api_get_domain_from_email() {
    local email="$1"
    echo "${email##*@}"
}

# Utility: Rate limiting helper
api_rate_limit() {
    sleep 0.125  # 1/8 second = 8 requests per second max
}

# Check dependencies
api_check_deps() {
    local missing=()
    
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v openssl >/dev/null 2>&1 || missing+=("openssl")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Install with: brew install ${missing[*]}"
        return 1
    fi
    
    return 0
}