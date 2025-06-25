#!/usr/bin/env python3
"""
TeamCity Diagnostic Script
Checks current versioned settings configuration
"""

import os
import sys
import json
import base64
import requests
from pathlib import Path

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
    print("🔍 TeamCity Configuration Diagnostic")
    print("====================================")
    print()
    
    # Load environment
    load_environment()
    
    # Configuration
    teamcity_url = "https://teamcity.devinfra.ru"
    admin_token = os.getenv('TEAMCITY_ADMIN_TOKEN')
    
    if not admin_token:
        print("❌ ERROR: TEAMCITY_ADMIN_TOKEN environment variable not set")
        sys.exit(1)
    
    api = TeamCityAPI(teamcity_url, admin_token)
    
    # Check VCS roots
    print("📂 VCS Roots:")
    response = api.get('vcs-roots')
    if response.status_code == 200:
        vcs_roots = response.json().get('vcs-root', [])
        for root in vcs_roots:
            print(f"  - {root['name']} (ID: {root['id']})")
            
            # Get details
            detail_response = api.get(f'vcs-roots/id:{root["id"]}')
            if detail_response.status_code == 200:
                details = detail_response.json()
                properties = {prop['name']: prop['value'] for prop in details.get('properties', {}).get('property', [])}
                print(f"    URL: {properties.get('url', 'unknown')}")
                print(f"    Branch: {properties.get('branch', 'unknown')}")
                print(f"    Auth Method: {properties.get('authMethod', 'unknown')}")
    else:
        print(f"❌ Failed to get VCS roots (HTTP {response.status_code})")
    
    print()
    
    # Check project features
    print("⚙️  Root Project Features:")
    response = api.get('projects/id:_Root/projectFeatures')
    if response.status_code == 200:
        features = response.json().get('projectFeature', [])
        for feature in features:
            print(f"  - {feature['type']} (ID: {feature['id']})")
            
            if feature['type'] == 'versionedSettings':
                # Get detailed feature info
                detail_response = api.get(f'projects/id:_Root/projectFeatures/id:{feature["id"]}')
                if detail_response.status_code == 200:
                    detail = detail_response.json()
                    properties = {prop['name']: prop['value'] for prop in detail.get('properties', {}).get('property', [])}
                    print(f"    Enabled: {properties.get('enabled', 'unknown')}")
                    print(f"    VCS Root ID: {properties.get('rootId', 'unknown')}")
                    print(f"    Build Settings: {properties.get('buildSettings', 'unknown')}")
                    print(f"    Import Settings: {properties.get('importSettings', 'unknown')}")
                    print(f"    Credentials Storage: {properties.get('credentialsStorageType', 'unknown')}")
                    print(f"    Show Changes: {properties.get('showChanges', 'unknown')}")
    else:
        print(f"❌ Failed to get project features (HTTP {response.status_code})")
    
    print()
    
    # Check current projects
    print("📋 Current Projects:")
    response = api.get('projects')
    if response.status_code == 200:
        projects = response.json().get('project', [])
        for project in projects:
            print(f"  - {project['name']} (ID: {project['id']})")
    else:
        print(f"❌ Failed to get projects (HTTP {response.status_code})")
    
    print()
    
    # Check build configurations
    print("🔧 Build Configurations:")
    response = api.get('buildTypes')
    if response.status_code == 200:
        build_types = response.json().get('buildType', [])
        for bt in build_types:
            print(f"  - {bt['name']} (ID: {bt['id']}) - Project: {bt.get('projectName', 'unknown')}")
    else:
        print(f"❌ Failed to get build types (HTTP {response.status_code})")
    
    print()
    print("🎯 Next Steps:")
    print("1. If VCS root exists but versioned settings aren't working:")
    print("   - Go to TeamCity UI → Administration → Versioned Settings")
    print("   - Manually configure the VCS root and sync settings")
    print("2. If projects aren't appearing:")
    print("   - Check that the .teamcity directory structure is correct in GitHub")
    print("   - Verify SSH key is configured for GitHub access")
    print("   - Check TeamCity logs for import errors")

if __name__ == "__main__":
    main()
