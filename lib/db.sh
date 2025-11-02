#!/bin/bash
# Database functions for Mail.tm CLI
# Handles all account storage and retrieval operations

source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"

# Initialize database if it doesn't exist
db_init() {
    if [[ ! -f "$DB_FILE" ]]; then
        local current_time=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
        cat > "$DB_FILE" << EOF
{
  "accounts": [],
  "metadata": {
    "version": "1.0",
    "created": "$current_time",
    "last_updated": "$current_time"
  }
}
EOF
        print_info "Database initialized at $DB_FILE"
    fi
}

# Update timestamp in metadata
db_update_timestamp() {
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    local temp_file=$(mktemp)
    
    if [[ -f "$DB_FILE" ]]; then
        jq --arg timestamp "$current_time" '.metadata.last_updated = $timestamp' "$DB_FILE" > "$temp_file" && mv "$temp_file" "$DB_FILE"
    fi
}

# Add account to database
db_add_account() {
    local name="$1"
    local address="$2"
    local password="$3"
    local token="$4"
    local account_id="$5"
    local domain="$6"
    
    db_init
    
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    local temp_file=$(mktemp)
    
    local account_record=$(jq -n \
        --arg name "$name" \
        --arg address "$address" \
        --arg password "$password" \
        --arg token "$token" \
        --arg account_id "$account_id" \
        --arg domain "$domain" \
        --arg created "$current_time" \
        '{
            name: $name,
            address: $address,
            password: $password,
            token: $token,
            account_id: $account_id,
            domain: $domain,
            created_at: $created,
            last_checked: null
        }')
    
    jq --argjson account "$account_record" '.accounts += [$account]' "$DB_FILE" > "$temp_file" && mv "$temp_file" "$DB_FILE"
    db_update_timestamp
}

# Get account by name
db_get_account() {
    local name="$1"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    jq -r --arg name "$name" '.accounts[] | select(.name == $name)' "$DB_FILE"
}

# Get account by address
db_get_account_by_address() {
    local address="$1"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    jq -r --arg address "$address" '.accounts[] | select(.address == $address)' "$DB_FILE"
}

# List all accounts
db_list_accounts() {
    db_init
    jq '.accounts' "$DB_FILE" 2>/dev/null || echo "[]"
}

# Remove account by name
db_remove_account() {
    local name="$1"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    jq --arg name "$name" '.accounts |= map(select(.name != $name))' "$DB_FILE" > "$temp_file" && mv "$temp_file" "$DB_FILE"
    db_update_timestamp
}

# Check if account exists by name
db_account_exists() {
    local name="$1"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    local count=$(jq -r --arg name "$name" '.accounts | map(select(.name == $name)) | length' "$DB_FILE")
    [[ "$count" -gt 0 ]]
}

# Update account token
db_update_token() {
    local name="$1"
    local new_token="$2"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    jq --arg name "$name" --arg token "$new_token" '
        .accounts |= map(
            if .name == $name then 
                .token = $token 
            else 
                . 
            end
        )' "$DB_FILE" > "$temp_file" && mv "$temp_file" "$DB_FILE"
    db_update_timestamp
}

# Update last checked time for monitoring
db_update_last_checked() {
    local name="$1"
    local timestamp="$2"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    jq --arg name "$name" --arg timestamp "$timestamp" '
        .accounts |= map(
            if .name == $name then 
                .last_checked = $timestamp 
            else 
                . 
            end
        )' "$DB_FILE" > "$temp_file" && mv "$temp_file" "$DB_FILE"
}

# Store emails for an account
db_store_emails() {
    local name="$1"
    local emails_json="$2"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    # Add emails array to the account if it doesn't exist, or update it
    jq --arg name "$name" --argjson emails "$emails_json" --arg sync_time "$current_time" '
        .accounts |= map(
            if .name == $name then 
                .emails = $emails | .last_sync = $sync_time
            else 
                . 
            end
        )' "$DB_FILE" > "$temp_file" && mv "$temp_file" "$DB_FILE"
    db_update_timestamp
}

# Get stored emails for an account
db_get_emails() {
    local name="$1"
    
    if [[ ! -f "$DB_FILE" ]]; then
        echo "[]"
        return 0
    fi
    
    jq -r --arg name "$name" '.accounts[] | select(.name == $name) | .emails // []' "$DB_FILE"
}

# Get specific email by index
db_get_email() {
    local name="$1"
    local index="$2"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    jq -r --arg name "$name" --argjson index "$((index-1))" '.accounts[] | select(.name == $name) | .emails[$index] // empty' "$DB_FILE"
}

# Update a specific email with full content
db_update_email() {
    local name="$1"
    local index="$2"
    local full_message="$3"
    
    if [[ ! -f "$DB_FILE" ]]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    
    jq --arg name "$name" --argjson index "$((index-1))" --argjson full_msg "$full_message" '
        .accounts |= map(
            if .name == $name then
                .emails[$index] = $full_msg
            else 
                . 
            end
        )' "$DB_FILE" > "$temp_file" && mv "$temp_file" "$DB_FILE"
    db_update_timestamp
}

# Get database stats
db_stats() {
    db_init
    
    local total_accounts=$(jq -r '.accounts | length' "$DB_FILE")
    local created_date=$(jq -r '.metadata.created' "$DB_FILE")
    local updated_date=$(jq -r '.metadata.last_updated' "$DB_FILE")
    
    echo "Database Statistics:"
    echo "==================="
    echo "Total accounts: $total_accounts"
    echo "Created: $created_date"
    echo "Last updated: $updated_date"
    echo "Database file: $DB_FILE"
}