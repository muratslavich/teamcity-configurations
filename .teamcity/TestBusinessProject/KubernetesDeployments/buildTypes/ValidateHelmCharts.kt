import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.finishBuildTrigger

/**
 * Helm Chart Validation (Test Business Project)
 */
object KubernetesDeployments_ValidateHelmCharts : BuildType({
    id("TestBusinessProject_KubernetesDeployments_ValidateHelmCharts")
    name = "Validate Helm Charts"
    description = "Validate Helm charts for business applications"

    steps {
        script {
            id = "RUNNER_1"
            name = "Validate Charts"
            scriptContent = """
                #!/bin/bash
                set -e
                
                echo "Validating Helm charts for business unit: %business.unit%"
                
                # Find and validate charts
                find %helm.chart.path% -name "Chart.yaml" -exec dirname {} \; | while read chart_dir; do
                    echo "Validating chart: $chart_dir"
                    helm lint "$chart_dir"
                    helm template %business.unit%-test "$chart_dir" --dry-run > /dev/null
                done
                
                echo "All charts validated successfully"
            """.trimIndent()
        }
    }

    triggers {
        finishBuildTrigger {
            id = "TRIGGER_1"
            buildType = "${JavaApplications_DockerBuild.id}"
            successfulOnly = true
        }
    }

    requirements {
        equals("system.agent.name", "helm-deploy-agent")
        exists("helm")
        exists("kubectl")
        equals("NO_JDK_AVAILABLE", "true")
    }

    artifactRules = "%helm.chart.path%/**/*.yaml => helm-charts/%business.unit%/"
})
