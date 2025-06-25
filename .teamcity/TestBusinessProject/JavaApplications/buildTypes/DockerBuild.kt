import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.triggers.finishBuildTrigger

/**
 * Docker Build Configuration (Test Business Project)
 */
object JavaApplications_DockerBuild : BuildType({
    id("TestBusinessProject_JavaApplications_DockerBuild")
    name = "Docker Build & Push"
    description = "Build Docker image and push to business registry"

    steps {
        dockerCommand {
            id = "RUNNER_1"
            name = "Build Docker Image"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                namesAndTags = """
                    %business.docker.registry%/java-app:latest
                    %business.docker.registry%/java-app:%build.number%
                """.trimIndent()
                
                buildArgs = """
                    BUILD_NUMBER=%build.number%
                    BUSINESS_UNIT=%business.unit%
                    JAR_FILE=app.jar
                """.trimIndent()
            }
        }
    }

    triggers {
        finishBuildTrigger {
            id = "TRIGGER_1"
            buildType = "${JavaApplications_MavenBuild.id}"
            successfulOnly = true
        }
    }

    requirements {
        equals("system.agent.name", "java-build-agent")
        exists("docker_compose")
    }

    dependencies {
        artifacts(JavaApplications_MavenBuild) {
            buildRule = lastSuccessful()
            artifactRules = "artifacts/%business.unit%/*.jar"
        }
    }
})
