import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

/**
 * VCS Root for Node.js Applications (Test Business Project)
 */
object NodejsApplications_GitRepository : GitVcsRoot({
    id("TestBusinessProject_NodejsApplications_GitRepository")
    name = "Node.js Applications Repository"
    
    url = "https://github.com/%git.organization%/%business.unit%-nodejs-applications.git"
    branch = "refs/heads/%git.default.branch%"
    
    branchSpec = """
        +:refs/heads/*
        +:refs/tags/*
        +:refs/pull/*/merge
        -:refs/heads/feature/temp-*
    """.trimIndent()
    
    checkoutPolicy = GitVcsRoot.AgentCheckoutPolicy.USE_MIRRORS
    
    authMethod = password {
        userName = "git"
        password = "credentialsJSON:github-token"
    }
})
