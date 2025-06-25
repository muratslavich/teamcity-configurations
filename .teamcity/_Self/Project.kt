import jetbrains.buildServer.configs.kotlin.*

/**
 * Root Project Configuration
 * 
 * Defines global settings, parameters, and configurations that apply to all projects.
 * This includes global agent requirements, shared parameters, and cleanup policies.
 */
object _Self : Project({
    name = "TeamCity Configuration Repository"
    description = "Central repository for all TeamCity build configurations using Configuration as Code"
    
    // Global project parameters
    params {
        // Default Java version for builds
        param("system.default.java.version", "17")
        
        // Docker registry configuration
        param("docker.registry.url", "registry.devinfra.ru")
        param("docker.registry.namespace", "teamcity")
        
        // Kubernetes configuration
        param("k8s.namespace.default", "default")
        param("k8s.cluster.name", "development")
        
        // Notification settings
        param("notifications.slack.channel", "#ci-cd")
        param("notifications.email.domain", "devinfra.ru")
        
        // Git configuration
        param("git.default.branch", "main")
        param("git.organization", "your-org")
    }
    
    // Global agent requirements
    features {
        feature {
            type = "project-agent-requirement"
            param("agent-requirement", "system.agent.name")
        }
    }
    
    // Cleanup policies
    cleanup {
        // Keep builds for 30 days
        keepRule {
            id = "KEEP_RULE_1"
            keepAtLeast = days(30)
            applyToBuilds {
                withStatus = successful()
            }
        }
        
        // Keep only last 10 failed builds
        keepRule {
            id = "KEEP_RULE_2" 
            keepAtLeast = builds(10)
            applyToBuilds {
                withStatus = failed()
            }
        }
        
        // Keep artifacts for successful builds for 7 days
        keepRule {
            id = "KEEP_RULE_3"
            keepAtLeast = days(7)
            applyToBuilds {
                withStatus = successful()
            }
            preserveArtifacts = true
        }
    }
})
