import jetbrains.buildServer.configs.kotlin.*

/**
 * Test Business Project
 * 
 * Parent project containing all business applications and their deployment configurations.
 * This project organizes related applications under a single business unit structure.
 * 
 * Sub-projects:
 * - JavaApplications: Backend services and APIs
 * - NodejsApplications: Frontend applications and Node.js services
 * - KubernetesDeployments: Deployment and infrastructure management
 * - DevOpsInfrastructure: Monitoring, logging, and operational tools
 */
object TestBusinessProject : Project({
    id("TestBusinessProject")
    name = "Test Business Project"
    description = "Business unit project containing all applications and their deployment pipelines"

    // Sub-projects
    subProject(JavaApplications)
    subProject(NodejsApplications)
    subProject(KubernetesDeployments)
    subProject(DevOpsInfrastructure)
    
    // Business-level parameters
    params {
        // Business unit configuration
        param("business.unit", "test-business")
        param("business.environment.prefix", "tb")
        
        // Common versioning
        param("business.version.major", "1")
        param("business.version.minor", "0")
        
        // Shared resources
        param("business.docker.registry", "%docker.registry.url%/test-business")
        param("business.k8s.namespace.prefix", "test-business")
        
        // Notification settings
        param("business.notifications.slack.channel", "#test-business-ci")
        param("business.notifications.email.list", "test-business-team@devinfra.ru")
        
        // Quality gates
        param("business.quality.coverage.threshold", "80")
        param("business.quality.security.level", "high")
    }
    
    // Business-level cleanup policies
    cleanup {
        // Keep builds for business projects longer
        keepRule {
            id = "BUSINESS_KEEP_RULE_1"
            keepAtLeast = days(45)
            applyToBuilds {
                withStatus = successful()
            }
        }
        
        // Keep critical artifacts longer
        keepRule {
            id = "BUSINESS_KEEP_RULE_2"
            keepAtLeast = days(14)
            applyToBuilds {
                withStatus = successful()
                withTags = "release"
            }
            preserveArtifacts = true
        }
    }
})
