import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

/**
 * VCS Root for Java Applications (Test Business Project)
 */
object JavaApplications_GitRepository : GitVcsRoot({
    id("TestBusinessProject_JavaApplications_GitRepository")
    name = "Java Applications Repository"
    
    url = "https://github.com/%git.organization%/%business.unit%-java-applications.git"
    branch = "refs/heads/%git.default.branch%"
    
    branchSpec = """
        +:refs/heads/*
        +:refs/tags/*
        -:refs/heads/feature/temp-*
    """.trimIndent()
    
    checkoutPolicy = GitVcsRoot.AgentCheckoutPolicy.USE_MIRRORS
    
    authMethod = password {
        userName = "git"
        password = "credentialsJSON:github-token"
    }
})
