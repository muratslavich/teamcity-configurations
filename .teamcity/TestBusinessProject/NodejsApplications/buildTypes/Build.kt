import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/**
 * Node.js Build Configuration (Test Business Project)
 */
object NodejsApplications_Build : BuildType({
    id("TestBusinessProject_NodejsApplications_Build")
    name = "Build"
    description = "Install dependencies, lint, and build Node.js application"

    vcs {
        root(NodejsApplications_GitRepository)
        cleanCheckout = true
    }

    steps {
        script {
            id = "RUNNER_1"
            name = "Install Dependencies & Build"
            scriptContent = """
                #!/bin/bash
                set -e
                
                echo "Node.js version:" && node --version
                echo "NPM version:" && npm --version
                
                # Install dependencies
                if [ -f "package-lock.json" ]; then
                    npm ci --production=false
                elif [ -f "yarn.lock" ]; then
                    yarn install --frozen-lockfile
                else
                    npm install
                fi
                
                # Run linting
                npm run lint || npm run lint:check || true
                
                # Build application
                export NODE_ENV=production
                export CI=true
                export BUSINESS_UNIT=%business.unit%
                %build.command%
                
                # Security audit
                npm audit --json > npm-audit-report.json || true
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
        equals("system.agent.name", "nodejs-build-agent")
        exists("nodejs")
        equals("NO_JDK_AVAILABLE", "true")
    }

    artifactRules = """
        dist/ => build-output/%business.unit%/
        build/ => build-output/%business.unit%/
        npm-audit-report.json => security-reports/
    """.trimIndent()
})
