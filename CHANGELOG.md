# Changelog

All notable changes to this TeamCity configuration repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial TeamCity Configuration as Code setup
- Java Applications project with Maven and Gradle support
- Node.js Applications project with npm/yarn support
- Kubernetes Deployments project with Helm validation
- DevOps Infrastructure project for monitoring and maintenance
- Multi-agent support (java-build-agent, nodejs-build-agent, helm-deploy-agent)
- JDK-free agent configurations for Node.js and Kubernetes workloads
- Docker image building and registry integration
- Security scanning for containers and Helm charts
- Comprehensive build chains and dependencies
- GitHub Actions validation workflow

### Security
- Implemented credentialsJSON for sensitive data
- Added security scanning for Docker images
- Configured Helm chart security validation
- Set up proper access controls and branch filters

## [1.0.0] - 2025-06-25

### Added
- Initial release of TeamCity Configuration as Code
- Support for Java, Node.js, and Kubernetes projects
- Automated build pipelines and deployment workflows
- Agent specialization and capability management
- Comprehensive documentation and setup guides

### Project Structure
- `.teamcity/settings.kts` - Root configuration
- `.teamcity/_Self/Project.kt` - Global project settings
- `.teamcity/JavaApplications/` - Java project configurations
- `.teamcity/NodejsApplications/` - Node.js project configurations
- `.teamcity/KubernetesDeployments/` - K8s deployment configurations
- `.teamcity/DevOpsInfrastructure/` - Infrastructure management

### Build Configurations
- **Java Applications**:
  - Maven Build with JDK 17/21 support
  - Gradle Build with parallel execution
  - Docker Build with registry push
  - Integration Tests and Security Scans

- **Node.js Applications**:
  - NPM/Yarn build with JDK-free agents
  - Code quality checks (ESLint, Prettier, TypeScript)
  - Security auditing with npm audit
  - Docker containerization

- **Kubernetes Deployments**:
  - Helm chart validation and security scanning
  - Multi-environment deployments (dev, staging, prod)
  - JDK-free Kubernetes agents
  - Automated deployment pipelines

### Agent Configurations
- **java-build-agent**: Full Java development stack with JDK 17/21
- **nodejs-build-agent**: JDK-free Node.js environment
- **helm-deploy-agent**: JDK-free Kubernetes deployment tools

### Features
- Versioned Settings integration with Git
- Automated project synchronization
- Build chains and dependencies
- Comprehensive artifact management
- Test result publishing and reporting
- Security scanning and compliance checks
- Multi-environment deployment support
- Agent capability-based builds
