import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.finishBuildTrigger

/**
 * Development Deployment Configuration (Test Business Project)
 */
object KubernetesDeployments_DeployDevelopment : BuildType({
    id("TestBusinessProject_KubernetesDeployments_DeployDevelopment")
    name = "Deploy to Development"
    description = "Deploy applications to development environment"

    steps {
        script {
            id = "RUNNER_1"
            name = "Deploy to Dev"
            scriptContent = """
                #!/bin/bash
                set -e
                
                echo "Deploying %business.unit% to development environment"
                
                kubectl config use-context %kubectl.context.dev%
                
                helm upgrade --install %business.unit%-dev %helm.chart.path% \
                    --namespace %k8s.namespace.dev% \
                    --create-namespace \
                    --timeout %helm.timeout% \
                    --set image.tag=%build.number% \
                    --set environment=development \
                    --set businessUnit=%business.unit%
                
                echo "Deployment to development completed"
            """.trimIndent()
        }
    }

    triggers {
        finishBuildTrigger {
            id = "TRIGGER_1"
            buildType = "${KubernetesDeployments_ValidateHelmCharts.id}"
            successfulOnly = true
            branchFilter = "+:main"
        }
    }

    requirements {
        equals("system.agent.name", "helm-deploy-agent")
        exists("helm")
        exists("kubectl")
        equals("NO_JDK_AVAILABLE", "true")
    }
})
