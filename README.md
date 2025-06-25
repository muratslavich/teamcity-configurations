# TeamCity Configuration Repository

This repository contains TeamCity Configuration as Code using Kotlin DSL for automated project management and build configurations.

## 🏗️ Project Structure

```
.teamcity/
├── settings.kts                       # Root configuration
├── _Self/
│   └── Project.kt                     # Global project settings
└── TestBusinessProject/               # Business unit project
    ├── Project.kt                     # Business project configuration
    ├── JavaApplications/              # Java applications
    │   ├── Project.kt
    │   ├── buildTypes/
    │   │   ├── MavenBuild.kt
    │   │   ├── GradleBuild.kt
    │   │   ├── DockerBuild.kt
    │   │   ├── IntegrationTests.kt
    │   │   └── SecurityScan.kt
    │   └── vcsRoots/
    │       └── GitRepository.kt
    ├── NodejsApplications/            # Node.js applications  
    │   ├── Project.kt
    │   ├── buildTypes/
    │   │   ├── Build.kt
    │   │   └── DockerBuild.kt
    │   └── vcsRoots/
    │       └── GitRepository.kt
    ├── KubernetesDeployments/         # Kubernetes deployments
    │   ├── Project.kt
    │   └── buildTypes/
    │       ├── ValidateHelmCharts.kt
    │       ├── DeployDevelopment.kt
    │       └── DeployProduction.kt
    └── DevOpsInfrastructure/          # Infrastructure management
        └── Project.kt
```

## 🚀 Features

### 🏢 Business Project Structure
- **TestBusinessProject**: Parent project for business unit organization
- **Hierarchical Organization**: Logical grouping of related applications
- **Business-Level Parameters**: Shared configuration across all sub-projects
- **Centralized Quality Gates**: Consistent standards and policies

### ☕ Java Applications (Sub-project)
- **Multi-JDK Support**: JDK 17 and 21 compatibility
- **Build Tools**: Maven and Gradle configurations
- **Docker Integration**: Automated image building and registry push
- **Security Scanning**: OWASP dependency checks and quality gates
- **Agent Requirements**: Uses `java-build-agent` with full JDK capabilities

### 🌐 Node.js Applications (Sub-project)
- **JDK-Free Builds**: Optimized Node.js-only environment
- **Package Managers**: npm and yarn support
- **Code Quality**: ESLint, Prettier, TypeScript checks
- **Security Scanning**: npm audit integration
- **Agent Requirements**: Uses `nodejs-build-agent` (NO_JDK_AVAILABLE=true)

### ☸️ Kubernetes Deployments (Sub-project)
- **Helm Charts**: Validation, security scanning, and deployment
- **Multi-Environment**: Development and production deployments
- **JDK-Free Deployments**: Kubernetes-focused agent configuration
- **Business Context**: Environment-specific namespaces and configurations
- **Agent Requirements**: Uses `helm-deploy-agent` (NO_JDK_AVAILABLE=true)

### 🔧 DevOps Infrastructure (Sub-project)
- **Infrastructure as Code**: Terraform and Ansible support
- **Business-Specific Monitoring**: Tailored monitoring and alerting
- **Environment Management**: Business unit infrastructure

## 🤖 Agent Configurations

### Java Build Agent (`java-build-agent`)
- **JDK Versions**: 17 (default), 21
- **Build Tools**: Maven, Gradle
- **Capabilities**: `jdk_17`, `jdk_21`, `maven`, `gradle`, `docker_compose`
- **Environment**: Full Java development stack

### Node.js Build Agent (`nodejs-build-agent`)
- **Runtime**: Node.js with npm/yarn
- **JDK Status**: JDK-FREE (NO_JDK_AVAILABLE=true)
- **Capabilities**: `nodejs`, `docker_compose`
- **Environment**: Optimized for frontend and Node.js builds

### Helm Deploy Agent (`helm-deploy-agent`)
- **Tools**: Helm, kubectl, Docker
- **JDK Status**: JDK-FREE (NO_JDK_AVAILABLE=true)
- **Capabilities**: `helm`, `kubectl`, `docker_compose`
- **Environment**: Kubernetes deployment focused

## 📋 Configuration Parameters

### Global Parameters (Root Project)
- `system.default.java.version`: Default JDK version (17)
- `docker.registry.url`: Container registry URL
- `git.organization`: GitHub organization name
- `k8s.namespace.default`: Default Kubernetes namespace

### Business-Level Parameters (TestBusinessProject)
- `business.unit`: Business unit identifier (test-business)
- `business.docker.registry`: Business-specific Docker registry
- `business.k8s.namespace.prefix`: Kubernetes namespace prefix
- `business.quality.coverage.threshold`: Code coverage requirement (80%)
- `business.quality.security.level`: Security scanning level (high)
- `business.notifications.slack.channel`: Business team Slack channel

### Project-Specific Parameters
- **Java**: `java.version.default`, `maven.goals.default`, `gradle.tasks.default`
- **Node.js**: `node.version`, `build.command`, `test.command`
- **Kubernetes**: `helm.chart.path`, `kubectl.context.dev`, `kubectl.context.prod`

## 🔄 Build Chains

### Java Application Pipeline (TestBusinessProject)
```
Maven/Gradle Build → Security Scan → Integration Tests → Docker Build → Helm Validation → K8s Deploy
```

### Node.js Application Pipeline (TestBusinessProject)
```
Node.js Build → Docker Build → Helm Validation → K8s Deploy
```

### Deployment Pipeline (TestBusinessProject)
```
Chart Validation → Development Deploy → Production Deploy (Manual Approval)
```

### Business-Level Quality Gates
- **Code Coverage**: Minimum 80% coverage requirement
- **Security Scanning**: High-level security checks mandatory
- **Business Context**: All artifacts tagged with business unit
- **Environment Isolation**: Business-specific namespaces and registries

## 🛡️ Security Features

- **Credential Management**: Uses TeamCity credentialsJSON
- **Security Scanning**: Docker image and Helm chart security checks
- **Access Control**: Branch-based deployment restrictions
- **Audit Trails**: Comprehensive build and deployment logging

## 🔧 Setup Instructions

### 1. Repository Configuration
```bash
# Clone this repository
git clone https://github.com/your-org/teamcity-configurations.git
cd teamcity-configurations

# Update repository URLs in VCS roots
# Edit .teamcity/*/vcsRoots/GitRepository.kt files
```

### 2. TeamCity Integration
```bash
# Configure TeamCity with Versioned Settings
ansible-playbook -i inventory/hosts projects/infra/playbooks/play-teamcity-modern.yml \
  --tags versioned-settings \
  -e teamcity_config_repo_url=https://github.com/your-org/teamcity-configurations.git \
  -e teamcity_admin_token=YOUR_TOKEN
```

### 3. Agent Setup
Ensure your TeamCity agents are configured with the required capabilities:

```yaml
# Agent configuration (from Ansible playbook)
teamcity_agents:
  - name: "java-build-agent"
    jdk_version: "17"
    capabilities: [jdk_17, jdk_21, maven, gradle, docker_compose]
  
  - name: "nodejs-build-agent"
    jdk_free: true
    capabilities: [nodejs, docker_compose]
  
  - name: "helm-deploy-agent"
    jdk_free: true
    capabilities: [helm, kubectl, docker_compose]
```

## 📝 Usage Examples

### Adding a New Java Project
1. Create project directory: `.teamcity/NewJavaProject/`
2. Copy and modify existing Java project configuration
3. Update `settings.kts` to include the new project
4. Commit and push changes

### Adding a New Build Configuration
1. Create build type file in appropriate `buildTypes/` directory
2. Add build type to project configuration
3. Configure VCS roots, triggers, and requirements
4. Test with dry-run before committing

### Modifying Agent Requirements
```kotlin
requirements {
    equals("system.agent.name", "java-build-agent")
    exists("jdk_17")
    exists("maven")
    exists("docker_compose")
}
```

## 🔍 Monitoring and Maintenance

### Build Health Monitoring
- **Success Rate Tracking**: Monitor build success rates per project
- **Performance Metrics**: Track build duration and resource usage
- **Agent Utilization**: Monitor agent usage and capacity

### Cleanup Policies
- **Build Retention**: 30 days for successful builds, 10 recent failed builds
- **Artifact Retention**: 7 days for successful builds
- **Log Retention**: Automatic cleanup based on TeamCity settings

## 🚀 Deployment Process

### Automatic Synchronization
TeamCity automatically synchronizes with this repository:
- **Trigger**: Git push to main branch
- **Validation**: Configuration syntax and structure checks
- **Application**: Projects and builds updated in TeamCity
- **Rollback**: Previous configuration preserved on errors

### Manual Synchronization
```bash
# Force synchronization in TeamCity
# Administration → Versioned Settings → Synchronize
```

## 📊 Project Overview

| Project | Parent | Build Configurations | Agent Type | JDK Required |
|---------|--------|---------------------|------------|--------------|
| TestBusinessProject | Root | - | - | Business Unit |
| Java Applications | TestBusinessProject | Maven, Gradle, Docker, Tests, Security | java-build-agent | ✅ JDK 17/21 |
| Node.js Applications | TestBusinessProject | Build, Docker | nodejs-build-agent | ❌ JDK-Free |
| Kubernetes Deployments | TestBusinessProject | Validation, Dev Deploy, Prod Deploy | helm-deploy-agent | ❌ JDK-Free |
| DevOps Infrastructure | TestBusinessProject | Infrastructure Management | Mixed | Varies |

### Business Project Benefits
- **Centralized Management**: Single business unit with all related projects
- **Shared Parameters**: Common configuration across all applications
- **Quality Consistency**: Unified quality gates and standards
- **Resource Organization**: Business-specific Docker registries and K8s namespaces
- **Team Notifications**: Business unit-specific Slack channels and email lists

## 🤝 Contributing

1. **Fork** this repository
2. **Create** a feature branch
3. **Modify** configuration files
4. **Test** with dry-run deployments
5. **Submit** a pull request

### Development Guidelines
- Follow existing naming conventions
- Test configurations before committing
- Document new parameters and features
- Ensure agent compatibility

## 📚 Resources

- [TeamCity Kotlin DSL Documentation](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html)
- [TeamCity REST API](https://www.jetbrains.com/help/teamcity/rest/teamcity-rest-api-documentation.html)
- [Versioned Settings](https://www.jetbrains.com/help/teamcity/storing-project-settings-in-version-control.html)

## 📞 Support

For questions and support:
- **TeamCity Issues**: Check build logs and configuration errors
- **Agent Problems**: Verify agent capabilities and requirements
- **Configuration Help**: Review Kotlin DSL documentation
- **Infrastructure**: Contact DevOps team

---

**Note**: This repository uses TeamCity Configuration as Code. All changes should be made through this repository and will be automatically synchronized with TeamCity.
