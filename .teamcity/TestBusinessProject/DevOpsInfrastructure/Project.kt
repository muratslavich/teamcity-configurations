import jetbrains.buildServer.configs.kotlin.*

/**
 * DevOps Infrastructure Project (Sub-project of Test Business Project)
 */
object DevOpsInfrastructure : Project({
    id("TestBusinessProject_DevOpsInfrastructure")
    name = "DevOps Infrastructure"
    description = "Infrastructure management and monitoring for business applications"

    params {
        param("terraform.version", "1.6.0")
        param("ansible.version", "latest")
        param("monitoring.namespace", "%business.k8s.namespace.prefix%-monitoring")
        param("backup.schedule", "0 2 * * *")
        param("infrastructure.environment", "%business.unit%")
    }
})
