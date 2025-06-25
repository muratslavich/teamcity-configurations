#!/usr/bin/env python3
"""
TeamCity Manual Configuration Guide
Provides step-by-step instructions for manual setup
"""

import os
from pathlib import Path

def load_environment():
    """Load environment variables from .env file"""
    env_file = Path('.env')
    if env_file.exists():
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value

def main():
    print("🔧 TeamCity Manual Configuration Guide")
    print("======================================")
    print()
    
    # Load environment
    load_environment()
    admin_token = os.getenv('TEAMCITY_ADMIN_TOKEN')
    
    print("✅ **Current Status:**")
    print("  - VCS Root: ✅ Created (TeamcityConfigurations_GitHubRepo)")
    print("  - Versioned Settings Feature: ✅ Exists (PROJECT_EXT_2)")
    print("  - Projects: ❌ Not synced yet")
    print()
    
    print("🎯 **Manual Configuration Steps:**")
    print()
    
    print("1. **Open TeamCity Administration:**")
    print("   - Go to: https://teamcity.devinfra.ru")
    print("   - Navigate to: Administration → Versioned Settings")
    print()
    
    print("2. **Configure Versioned Settings:**")
    print("   - Click on 'Enable versioned settings'")
    print("   - Set the following options:")
    print("     - Synchronization enabled: ✅ Yes")
    print("     - Project settings VCS root: TeamCity Configurations GitHub Repository")
    print("     - Settings format: Kotlin")
    print("     - Settings path in VCS: .teamcity")
    print("     - Use settings from VCS: ✅ Yes") 
    print("     - Show settings changes: ✅ Yes")
    print("     - Credentials storage type: prefer settings in VCS")
    print()
    
    print("3. **VCS Root Configuration:**")
    print("   If the VCS root needs configuration:")
    print("   - Go to: Administration → VCS Roots")
    print("   - Edit: 'TeamCity Configurations GitHub Repository'")
    print("   - Set:")
    print("     - Fetch URL: git@github.com:muratslavich/teamcity-configurations.git")
    print("     - Default branch: refs/heads/main")
    print("     - Authentication method: Default Private Key")
    print("     - Check 'Ignore known hosts database'")
    print()
    
    print("4. **Test VCS Connection:**")
    print("   - In the VCS Root configuration, click 'Test Connection'")
    print("   - Should show: 'Connection successful'")
    print()
    
    print("5. **Import Settings:**")
    print("   - Go back to: Administration → Versioned Settings")
    print("   - Click 'Import settings from VCS'")
    print("   - Wait for synchronization to complete")
    print()
    
    print("6. **Verify Import:**")
    print("   - Go to: Projects")
    print("   - Should see: TestBusinessProject")
    print("   - Expand to see subprojects:")
    print("     - JavaApplications")
    print("     - NodejsApplications") 
    print("     - KubernetesDeployments")
    print("     - DevOpsInfrastructure")
    print()
    
    print("🔑 **Authentication Info:**")
    if admin_token:
        print(f"   - Super User Token: {admin_token}")
    print("   - TeamCity URL: https://teamcity.devinfra.ru")
    print("   - GitHub Repository: git@github.com:muratslavich/teamcity-configurations.git")
    print()
    
    print("🚨 **Troubleshooting:**")
    print()
    print("   **If VCS connection fails:**")
    print("   - Ensure SSH key is added to TeamCity")
    print("   - Check GitHub repository permissions")
    print("   - Verify repository URL is accessible")
    print()
    
    print("   **If projects don't appear:**")
    print("   - Check .teamcity/settings.kts exists in repository")
    print("   - Verify Kotlin DSL syntax is correct")
    print("   - Check TeamCity server logs for import errors")
    print("   - Try manual 'Import settings from VCS' again")
    print()
    
    print("   **If sync keeps failing:**")
    print("   - Go to Administration → Diagnostics → Internal Properties")
    print("   - Look for versioned settings related logs")
    print("   - Check server logs: /opt/teamcity/logs/teamcity-server.log")
    print()
    
    print("✨ **Expected Result:**")
    print("   After successful configuration, you should see:")
    print("   - TestBusinessProject with 4 subprojects")
    print("   - 10+ build configurations across all projects")
    print("   - All configurations using proper agent requirements")
    print("   - Build chains and dependencies configured")
    print()
    
    print("🎉 **Success Verification:**")
    print("   1. Projects appear in TeamCity UI")
    print("   2. Build configurations are imported")
    print("   3. VCS roots are correctly configured") 
    print("   4. Agent requirements are set properly")
    print("   5. Build templates are available")

if __name__ == "__main__":
    main()
