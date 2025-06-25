#!/usr/bin/env python3
"""
TeamCity Configuration Deployment Script
Deploys TeamCity Configuration as Code using REST API
"""

import os
import sys
import json
import base64
import requests
import time
from pathlib import Path
from typing import Dict, List, Optional

# Disable SSL warnings for self-signed certificates
requests.packages.urllib3.disable_warnings()

class TeamCityAPI:
    def __init__(self, url: str, token: str):
        self.url = url.rstrip('/')
        self.token = token
        self.session = requests.Session()
        
        # Set up Basic authentication
        auth_string = f":{token}"
        auth_bytes = auth_string.encode('ascii')
        auth_b64 = base64.b64encode(auth_bytes).decode('ascii')
        
        self.session.headers.update({
            'Authorization': f'Basic {auth_b64}',
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        })
        
        # Disable SSL verification for development
        self.session.verify = False
    
    def get(self, endpoint: str) -> requests.Response:
        """Make GET request to TeamCity API"""
        url = f"{self.url}/app/rest/{endpoint.lstrip('/')}"
        return self.session.get(url)
    
    def post(self, endpoint: str, data: Dict) -> requests.Response:
        """Make POST request to TeamCity API"""
        url = f"{self.url}/app/rest/{endpoint.lstrip('/')}"
        return self.session.post(url, json=data)
    
    def put(self, endpoint: str, data: Dict) -> requests.Response:
        """Make PUT request to TeamCity API"""
        url = f"{self.url}/app/rest/{endpoint.lstrip('/')}"
        return self.session.put(url, json=data)
    
    def delete(self, endpoint: str) -> requests.Response:
        """Make DELETE request to TeamCity API"""
        url = f"{self.url}/app/rest/{endpoint.lstrip('/')}"
        return self.session.delete(url)

class TeamCityDeployer:
    def __init__(self, teamcity_url: str, admin_token: str, repo_url: str):
        self.api = TeamCityAPI(teamcity_url, admin_token)
        self.repo_url = repo_url
        self.teamcity_url = teamcity_url
        
    def test_connection(self) -> bool:
        """Test connection to TeamCity server"""
        print("🔗 Testing TeamCity connection...")
        try:
            response = self.api.get('server')
            if response.status_code == 200:
                print("✅ TeamCity connection successful")
                server_info = response.json()
                print(f"   Server version: {server_info.get('version', 'Unknown')}")
                return True
            else:
                print(f"❌ TeamCity connection failed (HTTP {response.status_code})")
                return False
        except Exception as e:
            print(f"❌ Connection error: {e}")
            return False
    
    def list_projects(self) -> List[Dict]:
        """List all projects"""
        print("📋 Current TeamCity projects:")
        try:
            response = self.api.get('projects')
            if response.status_code == 200:
                projects = response.json().get('project', [])
                for project in projects:
                    print(f"  - {project['name']} (ID: {project['id']})")
                return projects
            else:
                print(f"❌ Failed to list projects (HTTP {response.status_code})")
                return []
        except Exception as e:
            print(f"❌ Error listing projects: {e}")
            return []
    
    def get_vcs_roots(self) -> List[Dict]:
        """List all VCS roots"""
        try:
            response = self.api.get('vcs-roots')
            if response.status_code == 200:
                return response.json().get('vcs-root', [])
            return []
        except Exception as e:
            print(f"❌ Error getting VCS roots: {e}")
            return []
    
    def create_vcs_root(self) -> bool:
        """Create VCS root for the GitHub repository"""
        print("📂 Creating VCS Root...")
        
        # Check if VCS root already exists
        existing_roots = self.get_vcs_roots()
        for root in existing_roots:
            if root.get('name') == 'TeamCity Configurations GitHub Repository':
                print("   ⚠️  VCS Root already exists, skipping creation")
                return True
        
        vcs_root_data = {
            "id": "TeamcityConfigurations_GitHubRepo",
            "name": "TeamCity Configurations GitHub Repository",
            "vcsName": "jetbrains.git",
            "project": {"id": "_Root"},
            "properties": {
                "property": [
                    {"name": "branch", "value": "refs/heads/main"},
                    {"name": "url", "value": self.repo_url},
                    {"name": "authMethod", "value": "PRIVATE_KEY_DEFAULT"},
                    {"name": "ignoreKnownHosts", "value": "true"}
                ]
            }
        }
        
        try:
            response = self.api.post('vcs-roots', vcs_root_data)
            if response.status_code in [200, 201]:
                print("   ✅ VCS Root created successfully")
                return True
            else:
                print(f"   ❌ Failed to create VCS Root (HTTP {response.status_code})")
                print(f"   Response: {response.text}")
                return False
        except Exception as e:
            print(f"   ❌ Error creating VCS Root: {e}")
            return False
    
    def get_versioned_settings_status(self) -> Optional[Dict]:
        """Get versioned settings status"""
        print("🔍 Checking versioned settings status...")
        try:
            response = self.api.get('projects/id:_Root/projectFeatures')
            if response.status_code == 200:
                features = response.json().get('projectFeature', [])
                for feature in features:
                    if feature.get('type') == 'versionedSettings':
                        print(f"   📋 Found versioned settings feature (ID: {feature['id']})")
                        
                        # Get detailed feature info
                        detail_response = self.api.get(f'projects/id:_Root/projectFeatures/id:{feature["id"]}')
                        if detail_response.status_code == 200:
                            detail = detail_response.json()
                            properties = {prop['name']: prop['value'] for prop in detail.get('properties', {}).get('property', [])}
                            print(f"   - Enabled: {properties.get('enabled', 'unknown')}")
                            print(f"   - VCS Root: {properties.get('rootId', 'unknown')}")
                            print(f"   - Build Settings: {properties.get('buildSettings', 'unknown')}")
                            print(f"   - Import Settings: {properties.get('importSettings', 'unknown')}")
                            return detail
                        return feature
                print("   ⚠️  No versioned settings feature found")
                return None
            else:
                print(f"   ❌ Failed to get project features (HTTP {response.status_code})")
                return None
        except Exception as e:
            print(f"   ❌ Error checking versioned settings: {e}")
            return None

    def force_sync_from_vcs(self) -> bool:
        """Force synchronization from VCS by making a sync request"""
        print("🔄 Forcing synchronization from VCS...")
        try:
            # Try to trigger sync using the versioned settings sync endpoint
            response = self.api.post('projects/id:_Root/versionedSettings/commitCurrentSettings', {})
            if response.status_code in [200, 202]:
                print("   ✅ Sync triggered successfully")
                return True
            else:
                print(f"   ⚠️  Standard sync failed (HTTP {response.status_code}), trying alternative method...")
                
                # Alternative: reload settings from VCS
                response = self.api.post('projects/id:_Root/versionedSettings/reloadSettingsFromVcs', {})
                if response.status_code in [200, 202]:
                    print("   ✅ VCS reload triggered successfully")
                    return True
                else:
                    print(f"   ❌ VCS reload also failed (HTTP {response.status_code})")
                    return False
                    
        except Exception as e:
            print(f"   ❌ Error forcing sync: {e}")
            return False
    
    def configure_versioned_settings(self) -> bool:
        """Configure versioned settings for the Root project"""
        print("⚙️  Configuring versioned settings...")
        
        # Check current status
        current_settings = self.get_versioned_settings_status()
        if current_settings:
            print("   ✅ Versioned settings already exist, checking configuration...")
            properties = {prop['name']: prop['value'] for prop in current_settings.get('properties', {}).get('property', [])}
            
            # Check if it's pointing to the correct VCS root
            if properties.get('rootId') == 'TeamcityConfigurations_GitHubRepo':
                print("   ✅ Already pointing to correct VCS root")
                return True
            else:
                print(f"   ⚠️  Currently pointing to: {properties.get('rootId')}")
                print("   ℹ️  Manual configuration may be needed in TeamCity UI")
                return True
        
        versioned_settings_data = {
            "type": "versionedSettings",
            "properties": {
                "property": [
                    {"name": "credentialsStorageType", "value": "credentialsJSON"},
                    {"name": "enabled", "value": "true"},
                    {"name": "rootId", "value": "TeamcityConfigurations_GitHubRepo"},
                    {"name": "showChanges", "value": "true"},
                    {"name": "buildSettings", "value": "PREFER_VCS"},
                    {"name": "importSettings", "value": "true"}
                ]
            }
        }
        
        try:
            response = self.api.post('projects/id:_Root/projectFeatures', versioned_settings_data)
            if response.status_code in [200, 201]:
                print("   ✅ Versioned settings configured successfully")
                return True
            else:
                print(f"   ❌ Failed to configure versioned settings (HTTP {response.status_code})")
                print(f"   Response: {response.text}")
                return False
        except Exception as e:
            print(f"   ❌ Error configuring versioned settings: {e}")
            return False
    
    def update_versioned_settings(self, feature_id: str) -> bool:
        """Update existing versioned settings"""
        versioned_settings_data = {
            "type": "versionedSettings",
            "properties": {
                "property": [
                    {"name": "credentialsStorageType", "value": "credentialsJSON"},
                    {"name": "enabled", "value": "true"},
                    {"name": "rootId", "value": "TeamcityConfigurations_GitHubRepo"},
                    {"name": "showChanges", "value": "true"},
                    {"name": "buildSettings", "value": "PREFER_VCS"},
                    {"name": "importSettings", "value": "true"}
                ]
            }
        }
        
        try:
            response = self.api.put(f'projects/id:_Root/projectFeatures/id:{feature_id}', versioned_settings_data)
            if response.status_code == 200:
                print("   ✅ Versioned settings updated successfully")
                return True
            else:
                print(f"   ❌ Failed to update versioned settings (HTTP {response.status_code})")
                return False
        except Exception as e:
            print(f"   ❌ Error updating versioned settings: {e}")
            return False
    
    def trigger_sync(self) -> bool:
        """Trigger synchronization from VCS"""
        print("🔄 Triggering project synchronization...")
        try:
            # Get the versioned settings feature
            features = self.get_project_features("_Root")
            vs_feature = None
            for feature in features:
                if feature.get('type') == 'versionedSettings':
                    vs_feature = feature
                    break
            
            if not vs_feature:
                print("   ❌ No versioned settings feature found")
                return False
            
            # Trigger sync by updating the feature (this forces a refresh)
            feature_id = vs_feature['id']
            
            # First, get current feature data
            response = self.api.get(f'projects/id:_Root/projectFeatures/id:{feature_id}')
            if response.status_code != 200:
                print(f"   ❌ Failed to get feature data (HTTP {response.status_code})")
                return False
            
            feature_data = response.json()
            
            # Update with force sync
            response = self.api.put(f'projects/id:_Root/projectFeatures/id:{feature_id}', feature_data)
            if response.status_code == 200:
                print("   ✅ Synchronization triggered")
                return True
            else:
                print(f"   ❌ Failed to trigger sync (HTTP {response.status_code})")
                return False
                
        except Exception as e:
            print(f"   ❌ Error triggering sync: {e}")
            return False
    
    def wait_for_sync(self, timeout: int = 120) -> bool:
        """Wait for synchronization to complete"""
        print("⏳ Waiting for synchronization to complete...")
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            projects = self.list_projects()
            
            # Check if TestBusinessProject exists
            for project in projects:
                if project['id'] == 'TestBusinessProject':
                    print("   ✅ TestBusinessProject found - synchronization successful!")
                    return True
            
            print("   🔄 Still synchronizing... (waiting 10 seconds)")
            time.sleep(10)
        
        print(f"   ⏰ Timeout after {timeout} seconds")
        return False
    
    def validate_configuration(self) -> bool:
        """Validate that the configuration was imported correctly"""
        print("🔍 Validating configuration import...")
        
        projects = self.list_projects()
        project_names = [p['name'] for p in projects]
        
        expected_projects = [
            'TestBusinessProject'
        ]
        
        success = True
        for expected in expected_projects:
            if expected in project_names:
                print(f"   ✅ {expected} found")
            else:
                print(f"   ❌ {expected} missing")
                success = False
        
        return success

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
    print("🚀 TeamCity Configuration Deployment Script (Python)")
    print("===================================================")
    print()
    
    # Load environment
    load_environment()
    
    # Configuration
    teamcity_url = "https://teamcity.devinfra.ru"
    repo_url = "git@github.com:muratslavich/teamcity-configurations.git"
    admin_token = os.getenv('TEAMCITY_ADMIN_TOKEN')
    
    if not admin_token:
        print("❌ ERROR: TEAMCITY_ADMIN_TOKEN environment variable not set")
        print("Please set your TeamCity admin token:")
        print("  export TEAMCITY_ADMIN_TOKEN=your_actual_token")
        print("  python3 deploy.py")
        print()
        sys.exit(1)
    
    print(f"📋 Configuration:")
    print(f"  TeamCity URL: {teamcity_url}")
    print(f"  Repository: {repo_url}")
    print(f"  Token: {admin_token[:8]}...")
    print()
    
    # Initialize deployer
    deployer = TeamCityDeployer(teamcity_url, admin_token, repo_url)
    
    # Test connection
    if not deployer.test_connection():
        sys.exit(1)
    print()
    
    # List current projects
    deployer.list_projects()
    print()
    
    # Create VCS root
    if not deployer.create_vcs_root():
        print("❌ Failed to create VCS root")
        sys.exit(1)
    print()
    
    # Configure versioned settings
    if not deployer.configure_versioned_settings():
        print("⚠️  Versioned settings configuration had issues, but continuing...")
    print()
    
    # Force synchronization
    print("🔄 Attempting to force synchronization...")
    deployer.force_sync_from_vcs()
    print()
    
    # Wait for sync and validate
    if deployer.wait_for_sync():
        if deployer.validate_configuration():
            print("🎉 Deployment completed successfully!")
            print()
            print(f"🔗 Check your TeamCity instance: {teamcity_url}")
            print("   - Go to Projects to see TestBusinessProject")
            print("   - Check Administration → Versioned Settings for sync status")
        else:
            print("⚠️  Deployment completed but validation failed")
            print("   Please check TeamCity manually for any issues")
    else:
        print("❌ Synchronization did not complete within timeout")
        print("   Please check TeamCity manually:")
        print(f"   - Go to {teamcity_url}")
        print("   - Check Administration → Versioned Settings")
        print("   - Look for any error messages")

if __name__ == "__main__":
    main()
