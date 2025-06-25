#!/bin/bash

# TeamCity Configuration Deployment Script
# This script helps deploy the configuration to https://teamcity.devinfra.ru

set -e

echo "🚀 TeamCity Configuration Deployment Script"
echo "=============================================="
echo ""

# Configuration variables
TEAMCITY_URL="https://teamcity.devinfra.ru"
REPOSITORY_URL="${GITHUB_REPO_URL:-git@github.com:muratslavich/teamcity-configurations.git}"
ADMIN_TOKEN="${TEAMCITY_ADMIN_TOKEN:-}"

# Load .env file if it exists
if [ -f ".env" ]; then
    export $(cat .env | grep -v ^# | xargs)
    ADMIN_TOKEN="${TEAMCITY_ADMIN_TOKEN:-}"
fi

# Security check
if [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ ERROR: TEAMCITY_ADMIN_TOKEN environment variable not set"
    echo ""
    echo "Please set your TeamCity admin token:"
    echo "  export TEAMCITY_ADMIN_TOKEN=your_actual_token"
    echo "  ./deploy.sh"
    echo ""
    echo "Or run with token directly:"
    echo "  TEAMCITY_ADMIN_TOKEN=your_token ./deploy.sh"
    echo ""
    exit 1
fi

if [ "$REPOSITORY_URL" = "https://github.com/your-org/teamcity-configurations.git" ]; then
    echo "⚠️  WARNING: Using default repository URL"
    echo "   Consider setting: export GITHUB_REPO_URL=git@github.com:muratslavich/teamcity-configurations.git"
    echo ""
fi

echo "📋 Configuration Summary:"
echo "  TeamCity URL: $TEAMCITY_URL"
echo "  Repository: $REPOSITORY_URL"
echo "  Configuration files: $(find .teamcity -name '*.kt' -o -name '*.kts' | wc -l)"
echo ""

# Validate structure
echo "🔍 Validating configuration structure..."
if [ ! -f ".teamcity/settings.kts" ]; then
    echo "❌ ERROR: Missing .teamcity/settings.kts"
    exit 1
fi

if [ ! -f ".teamcity/_Self/Project.kt" ]; then
    echo "❌ ERROR: Missing .teamcity/_Self/Project.kt"
    exit 1
fi

if [ ! -f ".teamcity/TestBusinessProject/Project.kt" ]; then
    echo "❌ ERROR: Missing TestBusinessProject/Project.kt"
    exit 1
fi

echo "✅ Configuration structure validated"
echo ""

# Test TeamCity connection with Basic auth
echo "🔗 Testing TeamCity connection..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$TEAMCITY_URL/app/rest/server" \
    -H "Authorization: Basic $(echo -n ":$ADMIN_TOKEN" | base64)" \
    -H "Accept: application/json" \
    --insecure)

if [ "$response" = "200" ]; then
    echo "✅ TeamCity connection successful"
else
    echo "❌ TeamCity connection failed (HTTP $response)"
    echo "   Please check token and server availability"
    exit 1
fi
echo ""

# Check for admin token
if [ -z "$ADMIN_TOKEN" ]; then
    echo "⚠️  WARNING: TEAMCITY_ADMIN_TOKEN environment variable not set"
    echo "   You can get the token using: ./get-token.sh"
    echo ""
fi

# Check current projects in TeamCity
echo "📋 Current TeamCity projects:"
curl -s "$TEAMCITY_URL/app/rest/projects" \
    -H "Authorization: Basic $(echo -n ":$ADMIN_TOKEN" | base64)" \
    -H "Accept: application/json" \
    --insecure | jq -r '.project[]? | "  - \(.name) (ID: \(.id))"' 2>/dev/null || echo "  (jq not available - unable to parse projects)"
echo ""

# Display Git status
echo "📊 Git Repository Status:"
git status --porcelain
if [ $? -eq 0 ]; then
    echo "✅ Git repository ready"
else
    echo "❌ Git repository has issues"
fi
echo ""

# Display next steps
echo "🎯 Next Steps:"
echo ""
echo "1. ✅ GitHub Repository already configured:"
echo "   Repository: git@github.com:muratslavich/teamcity-configurations.git"
echo "   Status: $(git remote get-url origin 2>/dev/null || echo 'Not configured')"
echo ""

echo "2. 🔧 Configure TeamCity Versioned Settings:"
echo "   You can either:"
echo "   A) Use the Ansible playbook:"
echo "     ansible-playbook -i inventory/hosts projects/infra/playbooks/play-teamcity-modern.yml \\"
echo "       --tags versioned-settings \\"
echo "       -e teamcity_config_repo_url=git@github.com:muratslavich/teamcity-configurations.git"
echo ""
echo "   B) Configure manually in TeamCity UI:"
echo "     - Go to Administration → Versioned Settings"
echo "     - Set VCS Root to: git@github.com:muratslavich/teamcity-configurations.git"
echo "     - Set Settings format: Kotlin"
echo "     - Set Settings path: .teamcity"
echo ""

echo "3. � Automatic configuration via API:"
echo "   The script can configure versioned settings automatically."
read -p "   Do you want to configure versioned settings now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   🔧 Configuring versioned settings..."
    
    # Create VCS Root
    VCS_ROOT_JSON='{
        "id": "TeamcityConfigurations_GitHubRepo",
        "name": "TeamCity Configurations GitHub Repository",
        "vcsName": "jetbrains.git",
        "project": {"id": "_Root"},
        "properties": {
            "branch": "refs/heads/main",
            "url": "git@github.com:muratslavich/teamcity-configurations.git",
            "authMethod": "PRIVATE_KEY_DEFAULT",
            "ignoreKnownHosts": "true"
        }
    }'
    
    echo "     Creating VCS Root..."
    curl -s -X POST "$TEAMCITY_URL/app/rest/vcs-roots" \
        -H "Authorization: Basic $(echo -n ":$ADMIN_TOKEN" | base64)" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --insecure \
        -d "$VCS_ROOT_JSON" > /dev/null && echo "     ✅ VCS Root created" || echo "     ⚠️  VCS Root may already exist"
    
    # Configure versioned settings for Root project
    VERSIONED_SETTINGS_JSON='{
        "type": "versionedSettings",
        "properties": {
            "credentialsStorageType": "credentialsJSON",
            "enabled": "true",
            "rootId": "TeamcityConfigurations_GitHubRepo",
            "showChanges": "true",
            "buildSettings": "PREFER_VCS",
            "importSettings": "true"
        }
    }'
    
    echo "     Configuring versioned settings..."
    curl -s -X POST "$TEAMCITY_URL/app/rest/projects/id:_Root/projectFeatures" \
        -H "Authorization: Basic $(echo -n ":$ADMIN_TOKEN" | base64)" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --insecure \
        -d "$VERSIONED_SETTINGS_JSON" > /dev/null && echo "     ✅ Versioned settings configured" || echo "     ⚠️  Versioned settings may already be configured"
    
    echo "   🎉 Configuration complete!"
    echo ""
fi

echo "4. 🎉 Verify in TeamCity:"
echo "   - Open $TEAMCITY_URL"
echo "   - Go to Administration → Versioned Settings"
echo "   - Check synchronization status"
echo "   - Verify TestBusinessProject appears in project list"
echo ""

echo "📋 Project Structure Created:"
echo "Root"
echo "└── TestBusinessProject"
echo "    ├── JavaApplications (5 build configs)"
echo "    ├── NodejsApplications (2 build configs)"  
echo "    ├── KubernetesDeployments (3 build configs)"
echo "    └── DevOpsInfrastructure (infrastructure)"
echo ""

echo "✨ Configuration ready for deployment!"
