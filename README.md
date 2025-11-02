# Mail.tm CLI

A minimalist, modular command-line interface for managing temporary email accounts using the [Mail.tm](https://mail.tm) API.

## Features

- **🚀 Minimal Interface** - Simple commands, no verbose flags
- **📁 Modular Design** - Folder-based subcommand system  
- **💾 Offline Storage** - Emails stored locally in JSON for offline viewing
- **⚡ Real-time Monitoring** - Watch for new emails as they arrive
- **🔧 Easy Setup** - One-command installation and setup

## Installation

### Prerequisites
- `curl` - For API requests
- `jq` - For JSON processing  
- `openssl` - For password generation

On macOS:
```bash
brew install curl jq openssl
```

On Ubuntu/Debian:
```bash
sudo apt-get install curl jq openssl
```

### Setup
```bash
git clone https://github.com/AyushHRMSingh/Temp-Mail-CLI.git
cd temp-mail-cli
./setup.sh
```

## Usage

### Basic Commands

```bash
# Create account with generated password
./tm create myaccount

# Create account with specific password  
./tm create work mypassword123

# List all accounts
./tm list

# Show emails for account
./tm mail myaccount

# Read specific email (by number)
./tm read myaccount 1

# Watch for new emails (real-time)
./tm monitor myaccount

# Delete account
./tm delete myaccount
```

### Example Workflow

```bash
# 1. Create a temporary email account
$ ./tm create testwork
testwork: testwork@2200freefonts.com (xR8mK2pQ9vLn)

# 2. Use the email address for signups, then check for emails
$ ./tm mail testwork
Mail for testwork@2200freefonts.com:
2025-11-01 | noreply@service.com | Welcome to Our Service

# 3. Read the email content
$ ./tm read testwork 1
From: noreply@service.com
Subject: Welcome to Our Service
Date: 2025-11-01

Thank you for signing up! Click here to verify...

# 4. Monitor for new emails (exits on first new email)
$ ./tm monitor testwork
Monitoring testwork@2200freefonts.com (Ctrl+C to stop)...
NEW: support@service.com - Account Verification Required

# 5. Clean up when done
$ ./tm delete testwork
Deleted: testwork
```

## Architecture

### Directory Structure
```
temp-mail-cli/
├── tm                    # Main CLI router
├── config.sh            # Configuration and utilities
├── setup.sh             # Installation and setup script
├── accounts.json         # Local email database (created on first run)
├── lib/                  # Core modules
│   ├── db.sh            # Database operations
│   └── api.sh           # Mail.tm API wrapper
└── commands/            # Modular subcommands
    ├── create           # Account creation
    ├── delete           # Account deletion
    ├── list             # Account listing
    ├── mail             # Email listing
    ├── read             # Email reading
    └── monitor          # Real-time monitoring
```

### Modular Design

Each command is a **separate executable script** that:
- Sources required library modules
- Handles its own argument parsing  
- Is completely self-contained
- Can be added/removed independently

Adding a new command is as simple as creating an executable file in the `commands/` directory.

## Data Storage

Emails are stored locally in `accounts.json` for offline access:

```json
{
  "accounts": [
    {
      "name": "myaccount",
      "address": "myaccount@2200freefonts.com",
      "password": "generated_password",
      "token": "auth_token",
      "domain": "2200freefonts.com",
      "created_at": "2025-11-01T13:52:56.000Z",
      "emails": [
        {
          "id": "message_id",
          "from": {"address": "sender@example.com"},
          "subject": "Email Subject", 
          "text": "Email content...",
          "createdAt": "2025-11-01T13:53:19+00:00"
        }
      ],
      "last_sync": "2025-11-01T13:58:15.000Z"
    }
  ]
}
```

### Smart Caching
- **Online**: Fetches fresh emails from Mail.tm API
- **Offline**: Uses locally stored emails  
- **Sync**: Automatically stores new emails when fetched
- **Full Content**: Email text is stored on first read

## API Integration

Uses the [Mail.tm API](https://docs.mail.tm/) which provides:
- Free temporary email accounts
- No registration required
- 8 requests per second rate limit
- Multiple domain options
- Real-time message delivery

## Development

### Adding New Commands

1. Create executable script in `commands/` directory
2. Source required modules:
   ```bash
   source "$SCRIPT_DIR/../config.sh"
   source "$SCRIPT_DIR/../lib/api.sh"  
   source "$SCRIPT_DIR/../lib/db.sh"
   ```
3. Implement `main()` function
4. Make executable: `chmod +x commands/newcommand`

### Configuration

Edit `config.sh` to modify:
- API endpoints
- Rate limiting  
- Output colors
- Default settings

## Troubleshooting

### Common Issues

**Command not found: tm**
```bash
chmod +x tm
./tm help
```

**jq/curl not installed**
```bash
# macOS
brew install jq curl

# Ubuntu/Debian  
sudo apt-get install jq curl
```

**No domains available**
- Check internet connection
- Mail.tm service may be temporarily down
- Try again in a few minutes

**Account creation fails**
- Username may already be taken (try different name)
- Check API rate limits (max 8 requests/second)

### Reset Database
```bash
rm accounts.json
./tm create newaccount  # Will recreate database
```

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature-name`
3. Add your command in `commands/` directory
4. Test with existing accounts: `./tm list`
5. Commit changes: `git commit -am 'Add new feature'`  
6. Push branch: `git push origin feature-name`
7. Create Pull Request

## License

MIT License - feel free to use, modify, and distribute.

## Credits

- [Mail.tm](https://mail.tm) - Free temporary email service
- Built for developers who need quick, disposable email addresses for testing

---

**⚡ Quick Start**: `./setup.sh && ./tm create test`