# TeamCity Sync & Monitor Scripts

## Quick Start Guide

### 1. Setup Token
```bash
# Get or create a TeamCity token
./get-token.sh super    # Extract super user token from server
# OR
./get-token.sh create   # Create new user token interactively

# Test the token
./get-token.sh test
```

### 2. Trigger Sync & Watch Logs
```bash
# Full sync and monitoring (recommended)
./sync-and-watch.sh

# Individual commands
./sync-and-watch.sh sync     # Just trigger sync
./sync-and-watch.sh watch    # Just watch logs
./sync-and-watch.sh status   # Check sync status
```

## Script Details

### `get-token.sh` - Token Management
- **Purpose**: Manage TeamCity access tokens
- **Commands**:
  - `info` - Show current token status (default)
  - `super` - Extract super user token from server
  - `create` - Create new access token interactively
  - `test` - Validate existing token
  - `delete` - Remove stored token

### `sync-and-watch.sh` - Sync & Monitor
- **Purpose**: Trigger configuration sync and monitor logs
- **Commands**:
  - `full` - Trigger sync and watch events (default)
  - `sync` - Only trigger VCS synchronization
  - `watch` - Only watch TeamCity server logs
  - `status` - Check current synchronization status

## Configuration Files

### Token Storage
- `teamcity-token.txt` - Stores the TeamCity access token
- Environment variable: `TEAMCITY_TOKEN`

### Server Configuration
- Server: `teamcity.devinfra.ru`
- Log Node: `node5`
- Container: `teamcity_teamcity_1`

## Usage Examples

### First Time Setup
```bash
# 1. Get token
./get-token.sh super

# 2. Test configuration sync
./sync-and-watch.sh full
```

### Daily Workflow
```bash
# Make changes to .teamcity configuration files
# Commit and push changes
git add .teamcity/
git commit -m "Update build configuration"
git push

# Trigger immediate sync and watch for completion
./sync-and-watch.sh
```

### Troubleshooting
```bash
# Check token validity
./get-token.sh test

# Watch only logs for issues
./sync-and-watch.sh watch

# Check sync status without triggering
./sync-and-watch.sh status
```

## Log Monitoring Features

The sync-and-watch script provides:
- ✅ **Colored output** for different log types
- 🔍 **Filtered monitoring** for sync-related events
- ⏱️ **Timeout handling** for sync operations
- 🎯 **Specific event detection** (errors, warnings, sync events)

## Error Handling

### Common Issues
1. **Token expired/invalid**
   ```bash
   ./get-token.sh create  # Create new token
   ```

2. **SSH access issues**
   - Check SSH key access to `node5`
   - Verify Docker container is running

3. **Sync timeout**
   - Check TeamCity server status
   - Verify configuration file syntax
   - Review server logs for errors

### Getting Help
```bash
./get-token.sh help
./sync-and-watch.sh help
```

## Security Notes

- Token files are created with `600` permissions (owner read/write only)
- Tokens are validated before use
- Super user tokens should be used carefully
- Consider using personal access tokens for regular use
