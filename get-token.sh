#!/bin/bash

echo "🔑 TeamCity Token Extraction Guide"
echo "=================================="
echo ""

echo "The admin token might have changed. Here are ways to get the current token:"
echo ""

echo "📋 Method 1: From Docker container on the server"
echo "  ssh to your TeamCity server and run:"
echo "  ssh node5 \"sudo docker exec teamcity_teamcity_1 grep -o 'Super user authentication token: [0-9]*' /opt/teamcity/logs/teamcity-server.log | tail -1 | cut -d' ' -f5\""
echo ""

echo "📋 Method 2: From TeamCity Web UI"
echo "  1. Open https://teamcity.devinfra.ru"
echo "  2. If you see the setup wizard, look for 'Super user authentication token' in the page"
echo "  3. Or check browser developer tools for any token in the initial requests"
echo ""

echo "📋 Method 3: Generate new token via Ansible"
echo "  Re-run the token extraction task:"
echo "  ansible-playbook -i inventory/hosts projects/infra/playbooks/play-teamcity-modern.yml --tags token"
echo ""

echo "📋 Method 4: Check current TeamCity status"
echo "  curl -k https://teamcity.devinfra.ru/health"
echo ""

echo "Once you have the correct token, run:"
echo "  export TEAMCITY_ADMIN_TOKEN=YOUR_NEW_TOKEN"
echo "  ./test-connection.sh"
echo ""

echo "🔍 Let's check TeamCity health first..."
curl -k https://teamcity.devinfra.ru/health 2>/dev/null || curl -k https://teamcity.devinfra.ru/ 2>/dev/null | head -n 10

echo ""
echo "🚀 Attempting to extract token automatically..."
echo "Running: ssh node5 \"sudo docker exec teamcity_teamcity_1 grep -o 'Super user authentication token: [0-9]*' /opt/teamcity/logs/teamcity-server.log | tail -1 | cut -d' ' -f5\""
echo ""

TOKEN=$(ssh node5 "sudo docker exec teamcity_teamcity_1 grep -o 'Super user authentication token: [0-9]*' /opt/teamcity/logs/teamcity-server.log | tail -1 | cut -d' ' -f5" 2>/dev/null)

if [ -n "$TOKEN" ] && [ "$TOKEN" != "" ]; then
    echo "✅ Token found: $TOKEN"
    echo ""
    echo "To use this token, run:"
    echo "  export TEAMCITY_ADMIN_TOKEN=$TOKEN"
    echo "  ./test-connection.sh"
    echo ""
    echo "Or test connection immediately:"
    echo "  TEAMCITY_ADMIN_TOKEN=$TOKEN ./test-connection.sh"
else
    echo "❌ Could not extract token automatically."
    echo "Please try the manual methods listed above."
fi
