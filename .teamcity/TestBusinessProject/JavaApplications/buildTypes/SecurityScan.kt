import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/**
 * Security Scan Configuration (Test Business Project)
 */
object JavaApplications_SecurityScan : BuildType({
    id("TestBusinessProject_JavaApplications_SecurityScan")
    name = "Security Scan"
    description = "Run security scans for Java applications"

    steps {
        script {
            id = "RUNNER_1"
            name = "Security Scan"
            scriptContent = """
                #!/bin/bash
                set -e
                echo "Running security scan for %business.unit%"
                
                # OWASP Dependency Check
                mvn org.owasp:dependency-check-maven:check
                
                # Security level check
                echo "Security level: %business.quality.security.level%"
            """.trimIndent()
        }
    }

    requirements {
        equals("system.agent.name", "java-build-agent")
        exists("jdk_%java.version.default%")
        exists("maven")
    }

    artifactRules = "target/dependency-check-report.html => security-reports/"
})
