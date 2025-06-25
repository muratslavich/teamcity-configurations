import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.gradle
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/**
 * Gradle Build Configuration (Test Business Project)
 */
object JavaApplications_GradleBuild : BuildType({
    id("TestBusinessProject_JavaApplications_GradleBuild")
    name = "Gradle Build"
    description = "Compile, test and package Java application using Gradle"

    vcs {
        root(JavaApplications_GitRepository)
        cleanCheckout = true
    }

    steps {
        gradle {
            id = "RUNNER_1"
            name = "Gradle Build and Test"
            tasks = "%gradle.tasks.default%"
            jdkHome = "%JDK_SELECT_%java.version.default%%"
            gradleWrapperPath = "gradlew"
            
            gradleParams = """
                --parallel --build-cache --daemon --info
                -Dspring.profiles.active=test
                -Dbusiness.unit=%business.unit%
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            id = "TRIGGER_1"
            branchFilter = "+:*"
            perCheckinTriggering = true
        }
    }

    requirements {
        equals("system.agent.name", "java-build-agent")
        exists("jdk_%java.version.default%")
        exists("gradle")
    }

    artifactRules = "build/libs/*.jar => artifacts/%business.unit%/"
})
