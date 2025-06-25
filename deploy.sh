#!/bin/bash

# TeamCity Configuration Deployment Script
# This script helps deploy the configuration to https://teamcity.devinfra.ru

set -e

echo "🚀 TeamCity Configuration Deployment Script"
echo "=============================================="
echo ""

# Configuration variables
TEAMCITY_URL="https://teamcity.devinfra.ru"
REPOSITORY_URL="${GITHUB_REPO_URL:-https://github.com/your-org/teamcity-configurations.git}"
ADMIN_TOKEN="${TEAMCITY_ADMIN_TOKEN:-}"

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
    echo "   Consider setting: export GITHUB_REPO_URL=https://github.com/your-username/teamcity-configurations.git"
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

# Check for admin token
if [ -z "$ADMIN_TOKEN" ]; then
    echo "⚠️  WARNING: TEAMCITY_ADMIN_TOKEN environment variable not set"
    echo "   You can get the token from TeamCity logs:"
    echo "   grep 'Super user authentication token' /opt/teamcity/logs/teamcity-server.log"
    echo ""
fi

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
echo "1. 📂 Create GitHub Repository:"
echo "   - Go to https://github.com/new"
echo "   - Repository name: teamcity-configurations"
echo "   - Make it public or private (your choice)"
echo "   - Don't initialize with README (we already have one)"
echo ""

echo "2. 🔗 Add GitHub Remote:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/teamcity-configurations.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""

echo "3. 🔧 Configure TeamCity Versioned Settings:"
echo "   Run the Ansible playbook:"
echo "   ansible-playbook -i inventory/hosts projects/infra/playbooks/play-teamcity-modern.yml \\"
echo "     --tags versioned-settings \\"
echo "     -e teamcity_config_repo_url=https://github.com/YOUR_USERNAME/teamcity-configurations.git \\"
echo "     -e teamcity_admin_token=YOUR_TOKEN"
echo ""

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
