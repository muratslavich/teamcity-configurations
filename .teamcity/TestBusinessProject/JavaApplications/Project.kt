import jetbrains.buildServer.configs.kotlin.*

/**
 * Java Applications Project (Sub-project of Test Business Project)
 * 
 * Contains build configurations for Java-based applications including:
 * - Spring Boot applications
 * - Microservices
 * - Library projects
 * 
 * Supports Maven and Gradle builds with multi-JDK compatibility.
 * Inherits business-level parameters from parent project.
 */
object JavaApplications : Project({
    id("TestBusinessProject_JavaApplications")
    name = "Java Applications"
    description = "Java-based applications with Maven/Gradle builds and multi-JDK support"

    // Build configurations
    buildType(JavaApplications_MavenBuild)
    buildType(JavaApplications_GradleBuild)
    buildType(JavaApplications_IntegrationTests)
    buildType(JavaApplications_DockerBuild)
    buildType(JavaApplications_SecurityScan)
    
    // VCS roots
    vcsRoot(JavaApplications_GitRepository)
    
    // Project-specific parameters (inherits from business project)
    params {
        param("java.version.default", "17")
        param("java.version.alt", "21")
        param("maven.goals.default", "clean compile test package")
        param("gradle.tasks.default", "clean build test")
        param("docker.image.prefix", "%business.docker.registry%/java-app")
        param("sonar.project.key", "%business.unit%-java-applications")
        param("k8s.namespace", "%business.k8s.namespace.prefix%-java")
    }
    
    // Template for Java builds
    template {
        id("JavaBuildTemplate")
        name = "Java Build Template"
        
        params {
            param("java.version", "%java.version.default%")
            param("build.tool", "maven")
        }
        
        vcs {
            root(JavaApplications_GitRepository)
        }
        
        requirements {
            equals("system.agent.name", "java-build-agent")
            exists("jdk_%java.version%")
            exists("%build.tool%")
        }
        
        failureConditions {
            errorMessage = true
            failOnMetricChange {
                metric = BuildFailureOnMetric.MetricType.TEST_COUNT
                threshold = 20
                units = BuildFailureOnMetric.MetricUnit.PERCENT
                comparison = BuildFailureOnMetric.MetricComparison.LESS
            }
        }
    }
})
