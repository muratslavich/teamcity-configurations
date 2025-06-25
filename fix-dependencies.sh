#!/bin/bash

# TeamCity Dependency Fix Script
# This script provides fixes for common TeamCity DSL dependency issues

set -e

TEAMCITY_DIR=".teamcity"
POM_FILE="${TEAMCITY_DIR}/pom.xml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to create minimal pom.xml
create_minimal_pom() {
    print_status "Creating minimal pom.xml for TeamCity 2025.03.3..."
    
    cat > "$POM_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>TeamCity</groupId>
    <artifactId>teamcity-configs</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>pom</packaging>
    
    <name>TeamCity Configuration as Code</name>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <repositories>
        <repository>
            <id>teamcity-server</id>
            <url>https://teamcity.devinfra.ru/app/dsl-plugins-repository</url>
            <snapshots>
                <enabled>true</enabled>
            </snapshots>
        </repository>
    </repositories>
    
    <pluginRepositories>
        <pluginRepository>
            <id>teamcity-server</id>
            <url>https://teamcity.devinfra.ru/app/dsl-plugins-repository</url>
            <snapshots>
                <enabled>true</enabled>
            </snapshots>
        </pluginRepository>
    </pluginRepositories>
    
    <build>
        <sourceDirectory>${basedir}</sourceDirectory>
    </build>
</project>
EOF
    
    print_success "Minimal pom.xml created"
}

# Function to remove pom.xml entirely
remove_pom() {
    print_status "Removing pom.xml - TeamCity will use internal dependencies..."
    
    if [ -f "$POM_FILE" ]; then
        rm "$POM_FILE"
        print_success "pom.xml removed"
    else
        print_warning "No pom.xml found to remove"
    fi
}

# Function to show current pom status
show_pom_status() {
    echo ""
    print_status "Current pom.xml status:"
    
    if [ -f "$POM_FILE" ]; then
        echo "📄 pom.xml exists"
        echo "📏 Size: $(wc -c < "$POM_FILE") bytes"
        echo "📅 Modified: $(stat -f "%Sm" "$POM_FILE" 2>/dev/null || stat -c "%y" "$POM_FILE" 2>/dev/null || echo "unknown")"
        
        echo ""
        echo "🔍 Dependencies found:"
        if grep -q "dependency>" "$POM_FILE" 2>/dev/null; then
            grep -A2 -B1 "artifactId>" "$POM_FILE" | grep -E "(groupId|artifactId|version)" || echo "  None clearly identifiable"
        else
            echo "  No explicit dependencies found"
        fi
        
        echo ""
        echo "🏢 Repositories:"
        if grep -q "repository>" "$POM_FILE" 2>/dev/null; then
            grep -A3 "repository>" "$POM_FILE" | grep "<url>" | sed 's/.*<url>\(.*\)<\/url>.*/  - \1/' || echo "  None found"
        else
            echo "  No repositories found"
        fi
    else
        echo "❌ No pom.xml found"
    fi
}

# Function to check TeamCity server repository
check_server_repo() {
    print_status "Checking TeamCity server repository accessibility..."
    
    server_url="https://teamcity.devinfra.ru/app/dsl-plugins-repository"
    
    if curl -s --connect-timeout 10 --max-time 30 "$server_url" > /dev/null 2>&1; then
        print_success "TeamCity server repository is accessible"
    else
        print_warning "Cannot access TeamCity server repository"
        print_warning "This might be normal if authentication is required"
    fi
}

# Function to validate current configuration
validate_config() {
    print_status "Validating current configuration..."
    
    # Check settings.kts
    if [ -f "${TEAMCITY_DIR}/settings.kts" ]; then
        print_success "settings.kts found"
        
        # Check version
        version=$(grep "version.*=" "${TEAMCITY_DIR}/settings.kts" | head -1)
        if [ ! -z "$version" ]; then
            echo "  Version: $version"
        fi
    else
        print_error "settings.kts not found!"
        return 1
    fi
    
    # Check project files
    project_files=$(find "${TEAMCITY_DIR}" -name "Project.kt" | wc -l)
    echo "  Project files: $project_files"
    
    build_files=$(find "${TEAMCITY_DIR}" -path "*/buildTypes/*.kt" | wc -l)
    echo "  Build types: $build_files"
    
    return 0
}

# Function to show usage
show_usage() {
    echo "TeamCity Dependency Fix Tool"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  minimal    - Create minimal pom.xml (recommended)"
    echo "  remove     - Remove pom.xml entirely"
    echo "  status     - Show current pom.xml status"
    echo "  check      - Check server repository accessibility"
    echo "  validate   - Validate current configuration"
    echo "  help       - Show this help message"
    echo ""
    echo "Recommended fix sequence:"
    echo "  $0 minimal     # Try minimal pom.xml first"
    echo "  $0 remove      # If that fails, remove pom.xml entirely"
    echo ""
}

# Main execution
main() {
    local command="${1:-status}"
    
    print_status "TeamCity Dependency Fix Tool"
    print_status "Working directory: $(pwd)"
    print_status "TeamCity directory: $TEAMCITY_DIR"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -d "$TEAMCITY_DIR" ]; then
        print_error "TeamCity directory not found: $TEAMCITY_DIR"
        print_error "Please run this script from the project root"
        exit 1
    fi
    
    case "$command" in
        "minimal")
            create_minimal_pom
            show_pom_status
            print_status "Try committing and pushing this change"
            ;;
        "remove")
            remove_pom
            print_status "pom.xml removed - TeamCity will use internal dependencies"
            print_status "Try committing and pushing this change"
            ;;
        "status")
            show_pom_status
            ;;
        "check")
            check_server_repo
            ;;
        "validate")
            validate_config
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

# Run main function
main "$@"
