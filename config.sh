#!/bin/bash
# Mail.tm CLI Configuration File
# Contains all the constants and settings for the CLI

# API Configuration
API_BASE_URL="https://api.mail.tm"
MERCURE_BASE_URL="https://mercure.mail.tm/.well-known/mercure"

# Rate limiting (Mail.tm allows 8 queries per second)
RATE_LIMIT=8

# Database file
DB_FILE="$(dirname "${BASH_SOURCE[0]}")/accounts.json"

# Default settings
DEFAULT_PAGE_SIZE=30
REQUEST_TIMEOUT=10

# Colors for output (optional, for better UX)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions for colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}Success: $1${NC}"
}

print_info() {
    echo -e "${BLUE}Info: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}