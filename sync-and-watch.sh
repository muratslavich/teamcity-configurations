#!/bin/bash

# TeamCity Configuration Sync and Log Monitor Script
# This script triggers project synchronization and monitors TeamCity server logs

set -e

# Configuration
TEAMCITY_SERVER="teamcity.devinfra.ru"
TEAMCITY_URL="https://${TEAMCITY_SERVER}"
LOG_NODE="node5"
CONTAINER_NAME="teamcity_teamcity_1"
PROJECT_ID="_Root"
SYNC_TIMEOUT=300  # 5 minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✅ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠️  $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ❌ $1"
}

# Function to check if TeamCity token exists
check_token() {
    if [ -f "teamcity-token.txt" ]; then
        TOKEN=$(cat teamcity-token.txt)
        print_success "Found TeamCity token"
        return 0
    elif [ ! -z "$TEAMCITY_TOKEN" ]; then
        TOKEN="$TEAMCITY_TOKEN"
        print_success "Using environment token"
        return 0
    else
        print_error "No TeamCity token found!"
        print_warning "Please create 'teamcity-token.txt' file with your TeamCity token"
        print_warning "Or set TEAMCITY_TOKEN environment variable"
        print_warning "Get token from: ${TEAMCITY_URL}/profile.html?item=accessTokens"
        return 1
    fi
}

# Function to trigger VCS synchronization
trigger_sync() {
    print_status "Triggering VCS synchronization for project: $PROJECT_ID"
    
    # Trigger VCS sync via REST API
    response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/xml" \
        -X POST \
        "${TEAMCITY_URL}/app/rest/vcs-roots/id:_Root/commitHookNotification" \
        -d '<commitHookNotification/>' \
        -o /tmp/teamcity_sync_response.xml)
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "202" ]; then
        print_success "VCS synchronization triggered successfully"
        return 0
    else
        print_error "Failed to trigger sync. HTTP code: $http_code"
        if [ -f "/tmp/teamcity_sync_response.xml" ]; then
            cat /tmp/teamcity_sync_response.xml
        fi
        return 1
    fi
}

# Function to get current sync status
get_sync_status() {
    print_status "Checking synchronization status..."
    
    response=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/json" \
        "${TEAMCITY_URL}/app/rest/projects/id:$PROJECT_ID")
    
    if echo "$response" | jq -e '.vcsRoots' > /dev/null 2>&1; then
        print_success "Project configuration is accessible"
        return 0
    else
        print_warning "Project sync may still be in progress"
        return 1
    fi
}

# Function to watch TeamCity logs
watch_logs() {
    print_status "Starting log monitoring..."
    print_status "Watching TeamCity server logs on $LOG_NODE"
    print_warning "Press Ctrl+C to stop log monitoring"
    echo ""
    
    # Start log monitoring in background
    ssh "$LOG_NODE" "sudo docker logs --tail 50 -f $CONTAINER_NAME 2>&1" | while read line; do
        timestamp=$(date '+%H:%M:%S')
        
        # Highlight important log entries
        if echo "$line" | grep -qi "error\|exception\|failed"; then
            echo -e "${RED}[$timestamp]${NC} $line"
        elif echo "$line" | grep -qi "warning\|warn"; then
            echo -e "${YELLOW}[$timestamp]${NC} $line"
        elif echo "$line" | grep -qi "sync\|vcs\|commit\|configuration"; then
            echo -e "${GREEN}[$timestamp]${NC} $line"
        else
            echo -e "${NC}[$timestamp] $line"
        fi
    done
}

# Function to watch for specific sync events
watch_sync_events() {
    print_status "Monitoring for configuration sync events..."
    
    timeout $SYNC_TIMEOUT ssh "$LOG_NODE" "sudo docker logs --tail 0 -f $CONTAINER_NAME 2>&1" | while read line; do
        if echo "$line" | grep -qi "VCS.*sync\|configuration.*loaded\|DSL.*processed"; then
            print_success "Sync event: $line"
        elif echo "$line" | grep -qi "error.*sync\|failed.*configuration"; then
            print_error "Sync error: $line"
            break
        elif echo "$line" | grep -qi "warning.*sync"; then
            print_warning "Sync warning: $line"
        fi
    done
}

# Function to show usage
show_usage() {
    echo "TeamCity Configuration Sync and Monitor"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  sync     - Trigger VCS synchronization"
    echo "  watch    - Watch TeamCity server logs"
    echo "  status   - Check current sync status"
    echo "  full     - Trigger sync and watch logs (default)"
    echo "  help     - Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  TEAMCITY_TOKEN  - TeamCity access token"
    echo ""
    echo "Files:"
    echo "  teamcity-token.txt - File containing TeamCity access token"
    echo ""
    echo "Examples:"
    echo "  $0              # Trigger sync and watch logs"
    echo "  $0 sync         # Only trigger synchronization"
    echo "  $0 watch        # Only watch logs"
    echo "  $0 status       # Check sync status"
}

# Main execution
main() {
    local command="${1:-full}"
    
    print_status "TeamCity Configuration Sync Monitor"
    print_status "Server: $TEAMCITY_URL"
    print_status "Log Node: $LOG_NODE"
    echo ""
    
    case "$command" in
        "sync")
            if check_token; then
                trigger_sync
                get_sync_status
            fi
            ;;
        "watch")
            watch_logs
            ;;
        "status")
            if check_token; then
                get_sync_status
            fi
            ;;
        "full")
            if check_token; then
                trigger_sync
                sleep 2
                print_status "Starting log monitoring for sync events..."
                watch_sync_events &
                WATCH_PID=$!
                sleep 5
                kill $WATCH_PID 2>/dev/null || true
                get_sync_status
            fi
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

# Trap Ctrl+C
trap 'print_warning "Monitoring stopped by user"; exit 0' INT

# Check dependencies
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_warning "jq not found - JSON parsing will be limited"
fi

# Run main function
main "$@"
