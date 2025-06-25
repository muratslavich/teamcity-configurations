import jetbrains.buildServer.configs.kotlin.*

/**
 * Node.js Applications Project (Sub-project of Test Business Project)
 */
object NodejsApplications : Project({
    id("TestBusinessProject_NodejsApplications")
    name = "Node.js Applications"
    description = "Frontend and Node.js applications with npm/yarn builds"

    buildType(NodejsApplications_Build)
    buildType(NodejsApplications_DockerBuild)
    
    vcsRoot(NodejsApplications_GitRepository)
    
    params {
        param("node.version", "18")
        param("build.command", "npm run build")
        param("test.command", "npm run test")
        param("docker.image.prefix", "%business.docker.registry%/nodejs-app")
        param("k8s.namespace", "%business.k8s.namespace.prefix%-frontend")
    }
})
