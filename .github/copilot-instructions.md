# TeamCity Configuration Repository - Copilot Instructions

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Context
This repository contains TeamCity Configuration as Code using Kotlin DSL. All project configurations, build types, VCS roots, and templates are defined here and automatically synchronized with the TeamCity server.

## Code Guidelines

### TeamCity Kotlin DSL Best Practices
1. **Object Naming**: Use descriptive object names with project prefixes (e.g., `JavaApplications_MavenBuild`)
2. **IDs**: Use consistent ID patterns that match object names
3. **Parameters**: Use project-level parameters for reusable values
4. **Agent Requirements**: Specify exact agent capabilities and names
5. **Build Chains**: Use finish build triggers for sequential builds

### Agent Specifications
- **java-build-agent**: Multi-JDK Java builds (JDK 17, 21), Maven, Gradle, Docker
- **nodejs-build-agent**: JDK-FREE Node.js builds, npm/yarn, Docker (NO_JDK_AVAILABLE=true)
- **helm-deploy-agent**: JDK-FREE Kubernetes deployments, Helm, kubectl (NO_JDK_AVAILABLE=true)

### Parameter Conventions
- Use `%parameter.name%` syntax for TeamCity parameters
- Environment-specific parameters: `k8s.namespace.dev`, `k8s.namespace.prod`
- Tool versions: `java.version.default`, `node.version`
- Docker registry: `docker.registry.url`, `docker.registry.namespace`

### Build Configuration Structure
```kotlin
object ProjectName_BuildType : BuildType({
    id("ProjectName_BuildType")
    name = "Build Type Name"
    description = "Description"
    
    vcs { /* VCS configuration */ }
    steps { /* Build steps */ }
    triggers { /* Build triggers */ }
    requirements { /* Agent requirements */ }
    params { /* Build parameters */ }
    artifactRules = "..." // Artifact collection
    features { /* Additional features */ }
})
```

### Security Considerations
- Use `credentialsJSON:` for sensitive data
- Never hardcode passwords or tokens
- Use project features for OAuth configurations
- Implement security scanning in build pipelines

### JDK-Free Agent Configurations
For Node.js and Helm agents, ensure:
- `equals("NO_JDK_AVAILABLE", "true")` in requirements
- No JDK-related parameters or steps
- Focus on tool-specific capabilities (nodejs, helm, kubectl)

## File Organization
- `.teamcity/settings.kts`: Root configuration
- `.teamcity/_Self/Project.kt`: Global project settings
- `.teamcity/ProjectName/Project.kt`: Project definitions
- `.teamcity/ProjectName/buildTypes/`: Build configurations
- `.teamcity/ProjectName/vcsRoots/`: VCS root definitions

## Common Patterns
- Use templates for repeated build logic
- Implement build chains with dependencies
- Add comprehensive artifact collection
- Include test result publishing
- Configure cleanup policies
- Use branch filters for trigger control

When generating TeamCity configurations, ensure compatibility with the existing project structure and follow these established patterns.
