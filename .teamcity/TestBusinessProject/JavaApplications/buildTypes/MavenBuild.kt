import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.maven
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/**
 * Maven Build Configuration (Test Business Project)
 * 
 * Standard Maven build with test execution, artifact generation, and quality checks.
 * Supports multiple JDK versions and parallel execution.
 * Inherits business-level configuration and quality gates.
 */
object JavaApplications_MavenBuild : BuildType({
    id("TestBusinessProject_JavaApplications_MavenBuild")
    name = "Maven Build"
    description = "Compile, test and package Java application using Maven"

    vcs {
        root(JavaApplications_GitRepository)
        cleanCheckout = true
    }

    steps {
        maven {
            id = "RUNNER_1"
            name = "Maven Compile and Test"
            goals = "%maven.goals.default%"
            jdkHome = "%JDK_SELECT_%java.version.default%%"
            userSettingsSelection = "userSettingsSelection:default"
            localRepoScope = MavenBuildStep.RepositoryScope.maven_default
            
            // Maven options with business context
            mavenVersion = defaultProvidedVersion()
            runnerArgs = """
                -Dmaven.test.failure.ignore=false
                -Dspring.profiles.active=test
                -Dmaven.repo.local=%teamcity.build.tempDir%/.m2/repository
                -Dbusiness.unit=%business.unit%
                -Dbusiness.version=%business.version.major%.%business.version.minor%.%build.number%
            """.trimIndent()
        }
        
        maven {
            id = "RUNNER_2"
            name = "Generate Test Reports"
            goals = "surefire-report:report-only"
            jdkHome = "%JDK_SELECT_%java.version.default%%"
            executionPolicy = BuildStep.ExecutionPolicy.RUN_IF_FAILED
        }
        
        maven {
            id = "RUNNER_3"
            name = "Quality Gate Check"
            goals = "jacoco:report sonar:sonar"
            jdkHome = "%JDK_SELECT_%java.version.default%%"
            runnerArgs = """
                -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                -Dsonar.coverage.exclusions=**/*Test.java,**/*IT.java
                -Dsonar.projectKey=%sonar.project.key%
                -Dsonar.qualitygate.wait=true
            """.trimIndent()
            executionPolicy = BuildStep.ExecutionPolicy.RUN_IF_SUCCESSFUL
        }
    }

    triggers {
        vcs {
            id = "TRIGGER_1"
            branchFilter = """
                +:*
                -:refs/heads/feature/temp-*
                -:refs/heads/experimental/*
            """.trimIndent()
            perCheckinTriggering = true
            groupCheckinsByCommitter = true
        }
    }

    requirements {
        equals("system.agent.name", "java-build-agent")
        exists("jdk_%java.version.default%")
        exists("maven")
        exists("docker_compose")
    }

    params {
        param("java.version", "%java.version.default%")
        param("maven.goals", "%maven.goals.default%")
        param("business.artifact.name", "%business.unit%-java-app")
    }

    // Artifact rules with business context
    artifactRules = """
        target/*.jar => artifacts/%business.unit%/
        target/site/surefire-report.html => test-reports/
        target/surefire-reports/TEST-*.xml => test-reports/
        target/site/jacoco/jacoco.xml => coverage-reports/
    """.trimIndent()
    
    // Publish test results and quality metrics
    features {
        feature {
            type = "xml-report-plugin"
            param("xmlReportParsing.reportType", "surefire")
            param("xmlReportParsing.reportDirs", "target/surefire-reports/TEST-*.xml")
        }
        
        feature {
            type = "perfmon"
            param("perfmon.patterns", """
                target/surefire-reports/TEST-*.xml:surefire
            """.trimIndent())
        }
        
        // Business-level quality gates
        feature {
            type = "coverage"
            param("coverage.tool", "jacoco")
            param("coverage.threshold", "%business.quality.coverage.threshold%")
            param("coverage.jacoco.patterns", "target/site/jacoco/jacoco.xml")
        }
    }
    
    // Business-level failure conditions
    failureConditions {
        errorMessage = true
        failOnMetricChange {
            metric = BuildFailureOnMetric.MetricType.COVERAGE
            threshold = 80
            units = BuildFailureOnMetric.MetricUnit.PERCENT
            comparison = BuildFailureOnMetric.MetricComparison.LESS
        }
    }
})
