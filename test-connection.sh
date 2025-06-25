#!/bin/bash

# TeamCity Connection Test Script
echo "🧪 Testing TeamCity Connection..."
echo "================================="

TEAMCITY_URL="https://teamcity.devinfra.ru"
ADMIN_TOKEN="${TEAMCITY_ADMIN_TOKEN:-YOUR_TOKEN_HERE}"

# Check if token is provided
if [ "$ADMIN_TOKEN" = "YOUR_TOKEN_HERE" ]; then
    echo "❌ Admin token not provided!"
    echo ""
    echo "Please set the TEAMCITY_ADMIN_TOKEN environment variable:"
    echo "  export TEAMCITY_ADMIN_TOKEN=your_actual_token"
    echo "  ./test-connection.sh"
    echo ""
    echo "Or run with token directly:"
    echo "  TEAMCITY_ADMIN_TOKEN=your_token ./test-connection.sh"
    echo ""
    exit 1
fi

echo "🔗 TeamCity URL: $TEAMCITY_URL"
echo "🔑 Using admin token: ${ADMIN_TOKEN:0:8}..."
echo ""

# Test 1: Server status
echo "1️⃣ Testing server connectivity..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$TEAMCITY_URL/app/rest/server" \
    -H "Authorization: Basic $(echo -n ":$ADMIN_TOKEN" | base64)" \
    -H "Accept: application/json" \
    --insecure)

if [ "$response" = "200" ]; then
    echo "✅ Server is accessible and token is valid"
else
    echo "❌ Server connection failed (HTTP $response)"
    echo "   Check if TeamCity is running and token is correct"
    exit 1
fi

# Test 2: List current projects
echo ""
echo "2️⃣ Fetching current projects..."
curl -s "$TEAMCITY_URL/app/rest/projects" \
    -H "Authorization: Basic $(echo -n ":$ADMIN_TOKEN" | base64)" \
    -H "Accept: application/json" \
    --insecure | jq -r '.project[]? | "  - \(.name) (ID: \(.id))"' 2>/dev/null || echo "  (jq not available - raw response)"

# Test 3: Check versioned settings status  
echo ""
echo "3️⃣ Checking versioned settings status..."
curl -s "$TEAMCITY_URL/app/rest/projects/id:_Root/projectFeatures" \
    -H "Authorization: Basic $(echo -n ":$ADMIN_TOKEN" | base64)" \
    -H "Accept: application/json" \
    --insecure | grep -q "versionedSettings" && echo "✅ Versioned settings feature exists" || echo "⚠️  No versioned settings configured yet"

echo ""
echo "🎯 Ready to configure versioned settings!"
echo ""
echo "Next: Create GitHub repository and run the versioned settings configuration"
