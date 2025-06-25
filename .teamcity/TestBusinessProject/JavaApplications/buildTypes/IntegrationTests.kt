import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/**
 * Integration Tests Configuration (Test Business Project)
 */
object JavaApplications_IntegrationTests : BuildType({
    id("TestBusinessProject_JavaApplications_IntegrationTests")
    name = "Integration Tests"
    description = "Run integration tests for Java applications"

    steps {
        script {
            id = "RUNNER_1"
            name = "Integration Tests"
            scriptContent = """
                #!/bin/bash
                set -e
                echo "Running integration tests for %business.unit%"
                mvn verify -Dspring.profiles.active=integration-test
            """.trimIndent()
        }
    }

    requirements {
        equals("system.agent.name", "java-build-agent")
        exists("jdk_%java.version.default%")
        exists("maven")
    }
})
