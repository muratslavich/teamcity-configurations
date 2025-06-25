import jetbrains.buildServer.configs.kotlin.*

/**
 * Kubernetes Deployments Project (Sub-project of Test Business Project)
 */
object KubernetesDeployments : Project({
    id("TestBusinessProject_KubernetesDeployments")
    name = "Kubernetes Deployments"
    description = "Helm-based Kubernetes deployments for business applications"

    buildType(KubernetesDeployments_ValidateHelmCharts)
    buildType(KubernetesDeployments_DeployDevelopment)
    buildType(KubernetesDeployments_DeployProduction)
    
    params {
        param("k8s.namespace.dev", "%business.k8s.namespace.prefix%-dev")
        param("k8s.namespace.prod", "%business.k8s.namespace.prefix%-prod")
        param("helm.chart.path", "charts/")
        param("helm.timeout", "600s")
        param("kubectl.context.dev", "dev-cluster")
        param("kubectl.context.prod", "prod-cluster")
    }
})
