import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/**
 * Production Deployment Configuration (Test Business Project)
 */
object KubernetesDeployments_DeployProduction : BuildType({
    id("TestBusinessProject_KubernetesDeployments_DeployProduction")
    name = "Deploy to Production"
    description = "Deploy applications to production environment"

    steps {
        script {
            id = "RUNNER_1"
            name = "Deploy to Production"
            scriptContent = """
                #!/bin/bash
                set -e
                
                echo "Deploying %business.unit% to production environment"
                
                kubectl config use-context %kubectl.context.prod%
                
                helm upgrade --install %business.unit%-prod %helm.chart.path% \
                    --namespace %k8s.namespace.prod% \
                    --create-namespace \
                    --timeout %helm.timeout% \
                    --set image.tag=%build.number% \
                    --set environment=production \
                    --set businessUnit=%business.unit%
                
                echo "Production deployment completed"
            """.trimIndent()
        }
    }

    requirements {
        equals("system.agent.name", "helm-deploy-agent")
        exists("helm")
        exists("kubectl")
        equals("NO_JDK_AVAILABLE", "true")
    }

    params {
        param("requires.manual.approval", "true")
    }
})
