#!/bin/bash
# Setup script for Mail.tm CLI
# Handles installation, dependencies, and prevents user data commits

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() { echo -e "${RED}Error: $1${NC}" >&2; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

echo "Mail.tm CLI Setup"
echo "=================="
echo

# Check if this is a git repository
if [[ -d ".git" ]]; then
    print_info "Setting up git configuration to prevent user data commits..."
    
    # Create/update .gitignore
    cat > .gitignore << 'EOF'
# User data - never commit
accounts.json
*.log

# System files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
.tmpmails/
EOF
    
    print_success "Created .gitignore to protect user data"
    
    # If accounts.json exists and is tracked, remove it from git
    if git ls-files --error-unmatch accounts.json >/dev/null 2>&1; then
        print_warning "accounts.json is currently tracked by git"
        read -p "Remove accounts.json from git tracking? (y/N): " remove_tracking
        
        if [[ "$remove_tracking" == "y" || "$remove_tracking" == "Y" ]]; then
            git rm --cached accounts.json 2>/dev/null || true
            print_success "Removed accounts.json from git tracking"
        fi
    fi
else
    print_info "Not a git repository - skipping git configuration"
fi

# Check dependencies
print_info "Checking dependencies..."

missing_deps=()

if ! command -v curl >/dev/null 2>&1; then
    missing_deps+=("curl")
fi

if ! command -v jq >/dev/null 2>&1; then
    missing_deps+=("jq")
fi

if ! command -v openssl >/dev/null 2>&1; then
    missing_deps+=("openssl")
fi

if [[ ${#missing_deps[@]} -gt 0 ]]; then
    print_error "Missing dependencies: ${missing_deps[*]}"
    echo
    echo "Install them with:"
    
    # Detect OS and show appropriate install command
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install ${missing_deps[*]}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "  sudo apt-get install ${missing_deps[*]}"
        elif command -v yum >/dev/null 2>&1; then
            echo "  sudo yum install ${missing_deps[*]}"
        elif command -v pacman >/dev/null 2>&1; then
            echo "  sudo pacman -S ${missing_deps[*]}"
        else
            echo "  Use your package manager to install: ${missing_deps[*]}"
        fi
    else
        echo "  Install using your system's package manager: ${missing_deps[*]}"
    fi
    echo
    exit 1
fi

print_success "All dependencies found"

# Make scripts executable
print_info "Setting up permissions..."

chmod +x tm
chmod +x commands/*

print_success "Made scripts executable"

# Create example config if it doesn't exist
if [[ ! -f "accounts.json" ]]; then
    print_info "Creating initial database..."
    cat > accounts.json << 'EOF'
{
  "accounts": [],
  "metadata": {
    "version": "1.0",
    "created": "",
    "last_updated": ""
  }
}
EOF
    print_success "Created accounts.json database"
else
    print_warning "accounts.json already exists - keeping existing data"
fi

# Test basic functionality
print_info "Testing CLI functionality..."

if ./tm help >/dev/null 2>&1; then
    print_success "CLI is working correctly"
else
    print_error "CLI test failed"
    exit 1
fi

# Show completion message
echo
print_success "Setup complete!"
echo
echo "Next steps:"
echo "  1. Create your first account: ./tm create myaccount"  
echo "  2. List accounts: ./tm list"
echo "  3. Check for emails: ./tm mail myaccount"
echo "  4. Read emails: ./tm read myaccount 1"
echo
echo "For help: ./tm help"
echo

# Optional: Add to PATH
read -p "Add to PATH for system-wide access? (y/N): " add_to_path

if [[ "$add_to_path" == "y" || "$add_to_path" == "Y" ]]; then
    # Create a symlink in a common PATH location
    if [[ -w "/usr/local/bin" ]]; then
        ln -sf "$SCRIPT_DIR/tm" "/usr/local/bin/tm" 2>/dev/null && {
            print_success "Added 'tm' to PATH via /usr/local/bin"
            echo "You can now use 'tm' from anywhere!"
        } || {
            print_warning "Could not create symlink to /usr/local/bin"
            echo "You can manually add $SCRIPT_DIR to your PATH"
        }
    else
        print_info "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo "  export PATH=\"$SCRIPT_DIR:\$PATH\""
    fi
fi

echo
print_info "Happy email testing! 📧"