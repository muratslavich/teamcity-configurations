import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.triggers.finishBuildTrigger

/**
 * Node.js Docker Build Configuration (Test Business Project)
 */
object NodejsApplications_DockerBuild : BuildType({
    id("TestBusinessProject_NodejsApplications_DockerBuild")
    name = "Docker Build & Push"
    description = "Build Docker image for Node.js application"

    steps {
        dockerCommand {
            id = "RUNNER_1"
            name = "Build Docker Image"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                namesAndTags = """
                    %business.docker.registry%/nodejs-app:latest
                    %business.docker.registry%/nodejs-app:%build.number%
                """.trimIndent()
                
                buildArgs = """
                    BUILD_NUMBER=%build.number%
                    BUSINESS_UNIT=%business.unit%
                """.trimIndent()
            }
        }
    }

    triggers {
        finishBuildTrigger {
            id = "TRIGGER_1"
            buildType = "${NodejsApplications_Build.id}"
            successfulOnly = true
        }
    }

    requirements {
        equals("system.agent.name", "nodejs-build-agent")
        exists("docker_compose")
        equals("NO_JDK_AVAILABLE", "true")
    }

    dependencies {
        artifacts(NodejsApplications_Build) {
            buildRule = lastSuccessful()
            artifactRules = "build-output/%business.unit%/"
        }
    }
})
