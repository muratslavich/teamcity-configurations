#!/bin/bash

# TeamCity Configuration Validation Script
# This script validates the project structure and basic syntax

echo "=== TeamCity Configuration Validation ==="
echo "Date: $(date)"
echo ""

# Check basic structure
echo "1. Checking project structure..."
if [ -f ".teamcity/settings.kts" ]; then
    echo "   ✓ settings.kts found"
else
    echo "   ✗ settings.kts missing"
    exit 1
fi

if [ -f ".teamcity/pom.xml" ]; then
    echo "   ✓ pom.xml found"
else
    echo "   ✗ pom.xml missing"
    exit 1
fi

# Count configuration files
echo ""
echo "2. Configuration files summary:"
kotlin_files=$(find .teamcity -name "*.kt" -o -name "*.kts" | wc -l | tr -d ' ')
echo "   - Kotlin DSL files: $kotlin_files"

project_files=$(find .teamcity -name "Project.kt" | wc -l | tr -d ' ')
echo "   - Project definitions: $project_files"

buildtype_files=$(find .teamcity -path "*/buildTypes/*.kt" | wc -l | tr -d ' ')
echo "   - Build configurations: $buildtype_files"

vcsroot_files=$(find .teamcity -path "*/vcsRoots/*.kt" | wc -l | tr -d ' ')
echo "   - VCS roots: $vcsroot_files"

# Check for common issues
echo ""
echo "3. Checking for common issues..."

# Check for proper object naming
echo "   - Checking object naming conventions..."
inconsistent_names=$(grep -r "object.*:" .teamcity --include="*.kt" | grep -v "_" | wc -l | tr -d ' ')
if [ "$inconsistent_names" -gt 0 ]; then
    echo "     ⚠ Some objects may not follow naming conventions"
else
    echo "     ✓ Object naming looks good"
fi

# Check for proper imports
echo "   - Checking import statements..."
missing_imports=$(grep -L "import jetbrains.buildServer.configs.kotlin" .teamcity/**/*.kt 2>/dev/null | wc -l | tr -d ' ')
if [ "$missing_imports" -gt 0 ]; then
    echo "     ⚠ Some files may be missing imports"
else
    echo "     ✓ Import statements look good"
fi

# Check for agent requirements
echo "   - Checking agent requirements..."
agent_refs=$(grep -r "java-build-agent\|nodejs-build-agent\|helm-deploy-agent" .teamcity --include="*.kt" | wc -l | tr -d ' ')
echo "     - Agent requirement references: $agent_refs"

echo ""
echo "4. Project structure tree:"
if command -v tree >/dev/null 2>&1; then
    tree .teamcity -I "target|.git"
else
    find .teamcity -type d | sort | sed 's/[^-][^\/]*\//  /g;s/^  //;s/-/|/'
fi

echo ""
echo "=== Validation completed ==="
echo ""
echo "To resolve IDE compilation issues:"
echo "1. Open the .teamcity folder in IntelliJ IDEA as a Maven project"
echo "2. Let IntelliJ download dependencies automatically"
echo "3. Mark .teamcity as the project root"
echo "4. If using VS Code, install the Kotlin extension"
