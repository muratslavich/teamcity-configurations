#!/bin/bash

# TeamCity Token Management Script
# Helps with getting and storing TeamCity access tokens

set -e

TEAMCITY_SERVER="teamcity.devinfra.ru"
TEAMCITY_URL="https://${TEAMCITY_SERVER}"
TOKEN_FILE="teamcity-token.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if token file exists
check_existing_token() {
    if [ -f "$TOKEN_FILE" ]; then
        print_success "Token file already exists: $TOKEN_FILE"
        return 0
    else
        return 1
    fi
}

# Function to validate token
validate_token() {
    local token="$1"
    print_status "Validating token against TeamCity server..."
    
    response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/json" \
        "${TEAMCITY_URL}/app/rest/users/current" \
        -o /tmp/token_validation.json)
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        if [ -f "/tmp/token_validation.json" ] && command -v jq &> /dev/null; then
            username=$(jq -r '.username // "unknown"' /tmp/token_validation.json 2>/dev/null || echo "unknown")
            print_success "Token is valid for user: $username"
        else
            print_success "Token is valid"
        fi
        return 0
    else
        print_error "Token validation failed (HTTP $http_code)"
        if [ -f "/tmp/token_validation.json" ]; then
            cat /tmp/token_validation.json
        fi
        return 1
    fi
}

# Function to get super user token from server
get_super_user_token() {
    print_status "Attempting to get super user token from server..."
    echo ""
    echo "🔑 TeamCity Super User Token Extraction"
    echo "======================================="
    echo ""
    echo "📋 Method 1: From Docker container on the server"
    echo "  ssh node5 \"sudo docker exec teamcity_teamcity_1 grep -o 'Super user authentication token: [0-9]*' /opt/teamcity/logs/teamcity-server.log | tail -1 | cut -d' ' -f5\""
    echo ""
    echo "📋 Method 2: From TeamCity Web UI"
    echo "  1. Open ${TEAMCITY_URL}"
    echo "  2. If you see the setup wizard, look for 'Super user authentication token' in the page"
    echo "  3. Or check browser developer tools for any token in the initial requests"
    echo ""
    echo "📋 Method 3: From server logs directly"
    echo "  ssh node5 \"sudo docker logs teamcity_teamcity_1 2>&1 | grep -i 'super user' | tail -5\""
    echo ""
    
    # Try to get token automatically
    print_status "Attempting automatic token extraction..."
    TOKEN=$(ssh node5 "sudo docker exec teamcity_teamcity_1 grep -o 'Super user authentication token: [0-9]*' /opt/teamcity/logs/teamcity-server.log | tail -1 | cut -d' ' -f5" 2>/dev/null || echo "")
    
    if [ -n "$TOKEN" ] && [ "$TOKEN" != "" ]; then
        print_success "Token found: $TOKEN"
        echo ""
        read -p "Save this token to $TOKEN_FILE? (y/n): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$TOKEN" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"
            print_success "Token saved to $TOKEN_FILE"
            validate_token "$TOKEN"
        fi
    else
        print_warning "Could not extract token automatically"
    fi
}

# Function to create token interactively
create_token() {
    echo ""
    print_status "Creating TeamCity access token..."
    echo ""
    echo "Steps to create a TeamCity access token:"
    echo "1. Open your browser and go to: ${TEAMCITY_URL}/profile.html?item=accessTokens"
    echo "2. Log in to TeamCity if prompted"
    echo "3. Click 'Create access token'"
    echo "4. Set name: 'Configuration Sync Token'"
    echo "5. Leave expiration empty (never expires) or set appropriate date"
    echo "6. Copy the generated token"
    echo ""
    
    read -p "Have you created the token? (y/n): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Please create the token first, then run this script again"
        exit 1
    fi
    
    echo ""
    read -s -p "Paste your TeamCity token: " token
    echo ""
    
    if [ -z "$token" ]; then
        print_error "No token provided"
        exit 1
    fi
    
    # Validate the token
    if validate_token "$token"; then
        # Save to file
        echo "$token" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        print_success "Token saved to $TOKEN_FILE with secure permissions"
    else
        print_error "Token validation failed - not saving"
        exit 1
    fi
}

# Function to test existing token
test_token() {
    if [ -f "$TOKEN_FILE" ]; then
        local token=$(cat "$TOKEN_FILE")
        print_status "Testing existing token..."
        validate_token "$token"
    else
        print_error "No token file found: $TOKEN_FILE"
        exit 1
    fi
}

# Function to delete token
delete_token() {
    if [ -f "$TOKEN_FILE" ]; then
        rm "$TOKEN_FILE"
        print_success "Token file deleted: $TOKEN_FILE"
    else
        print_warning "No token file found to delete"
    fi
}

# Function to show token info
show_info() {
    if [ -f "$TOKEN_FILE" ]; then
        local token=$(cat "$TOKEN_FILE")
        print_status "Token file: $TOKEN_FILE"
        print_status "Token length: ${#token} characters"
        print_status "First 8 characters: ${token:0:8}..."
        
        # Test the token
        echo ""
        validate_token "$token"
    else
        print_warning "No token file found: $TOKEN_FILE"
        echo ""
        get_super_user_token
    fi
}

# Function to show usage
show_usage() {
    echo "TeamCity Token Manager"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  create   - Create and save new access token (interactive)"
    echo "  test     - Test existing token"
    echo "  info     - Show information about current token"
    echo "  super    - Show how to get super user token"
    echo "  delete   - Delete stored token"
    echo "  help     - Show this help message"
    echo ""
    echo "Files:"
    echo "  $TOKEN_FILE - Stores the TeamCity access token"
    echo ""
    echo "Examples:"
    echo "  $0 create    # Create new token interactively"
    echo "  $0 test      # Test existing token"
    echo "  $0 info      # Show token information"
    echo "  $0 super     # Show super user token extraction"
}

# Main execution
main() {
    local command="${1:-info}"
    
    print_status "TeamCity Token Manager"
    print_status "Server: $TEAMCITY_URL"
    print_status "Token file: $TOKEN_FILE"
    echo ""
    
    case "$command" in
        "create")
            if check_existing_token; then
                read -p "Token file already exists. Overwrite? (y/n): " -r
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_warning "Operation cancelled"
                    exit 0
                fi
            fi
            create_token
            ;;
        "test")
            test_token
            ;;
        "info")
            show_info
            ;;
        "super")
            get_super_user_token
            ;;
        "delete")
            delete_token
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    exit 1
fi

# Run main function
main "$@"
