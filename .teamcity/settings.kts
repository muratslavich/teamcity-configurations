import jetbrains.buildServer.configs.kotlin.*

/**
 * TeamCity Configuration as Code
 * 
 * This repository contains all TeamCity project configurations using Kotlin DSL.
 * It supports automatic synchronization with TeamCity server when changes are pushed.
 * 
 * Project Structure:
 * Root
 * └── TestBusinessProject
 *     ├── JavaApplications: Java-based applications with Maven/Gradle builds
 *     ├── NodejsApplications: Frontend and Node.js applications  
 *     ├── KubernetesDeployments: Helm-based Kubernetes deployments
 *     └── DevOpsInfrastructure: Infrastructure and monitoring projects
 */

version = "2024.07"

// Root project configuration
project(_Self)

// Business project containing all applications
project(TestBusinessProject)
