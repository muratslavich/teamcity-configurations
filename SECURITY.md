# Security Guidelines for TeamCity Configuration Repository

## 🔒 Security Best Practices

### Environment Variables
Always use environment variables for sensitive information:

```bash
# Set your TeamCity admin token
export TEAMCITY_ADMIN_TOKEN=your_actual_token_here

# Set your GitHub repository URL  
export GITHUB_REPO_URL=https://github.com/your-username/teamcity-configurations.git

# Optional: Set GitHub token for private repositories
export GITHUB_TOKEN=your_github_token_here
```

### Never Commit Secrets
The following files are protected by `.gitignore`:
- `*.token` - Token files
- `teamcity-token.txt` - TeamCity token storage
- `admin-token` - Admin token files
- `.env*` - Environment files
- `secrets.yaml` - Secret configuration files

### Testing Connection Securely
```bash
# Method 1: Export token first
export TEAMCITY_ADMIN_TOKEN=your_token
./test-connection.sh

# Method 2: Inline token (not stored)
TEAMCITY_ADMIN_TOKEN=your_token ./test-connection.sh
```

### Deployment Security
```bash
# Set required environment variables
export TEAMCITY_ADMIN_TOKEN=your_token
export GITHUB_REPO_URL=https://github.com/your-username/teamcity-configurations.git

# Run deployment
./deploy.sh
```

### Getting TeamCity Token Securely
```bash
# Use the provided script to extract token
./get-token.sh

# Or use Ansible to get the token
ansible-playbook -i inventory/hosts projects/infra/playbooks/play-teamcity-modern.yml --tags token
```

## 🛡️ What's Protected

### Files with Sensitive Information
- All scripts use environment variables instead of hardcoded values
- Token patterns are excluded from git commits
- Default values are placeholder text, not real tokens

### TeamCity Credentials
- All API calls use `credentialsJSON:` references
- No passwords or tokens are hardcoded in Kotlin DSL
- Business unit isolation prevents cross-project access

### Repository Access
- VCS roots use credential references
- GitHub tokens are handled via TeamCity credential store
- No authentication details in version control

## 🚨 Emergency Procedures

### If Token is Compromised
1. **Revoke** the current token in TeamCity
2. **Generate** a new super user token
3. **Update** your environment variable
4. **Test** the connection with new token

### If Repository is Compromised
1. **Rotate** all GitHub tokens
2. **Update** credential references in TeamCity
3. **Review** commit history for any leaked secrets
4. **Force push** clean history if necessary

## ✅ Verification Checklist

Before committing changes:
- [ ] No hardcoded tokens in any files
- [ ] All sensitive values use environment variables
- [ ] `.gitignore` covers all token file patterns
- [ ] Scripts validate token presence before execution
- [ ] Documentation references placeholder values only

## 📖 Usage Examples

### Safe Development Workflow
```bash
# 1. Set up environment (one time)
export TEAMCITY_ADMIN_TOKEN=your_token
export GITHUB_REPO_URL=https://github.com/your-username/teamcity-configurations.git

# 2. Test connection
./test-connection.sh

# 3. Make configuration changes
# Edit .teamcity/ files as needed

# 4. Validate changes
./.vscode/tasks.json # Run validation tasks

# 5. Deploy to TeamCity
./deploy.sh

# 6. Commit changes (tokens are safe)
git add .
git commit -m "Update TeamCity configuration"
git push
```

### Ansible Integration
```bash
# Use with Ansible playbook
ansible-playbook -i inventory/hosts projects/infra/playbooks/play-teamcity-modern.yml \
  --tags versioned-settings \
  -e teamcity_config_repo_url="$GITHUB_REPO_URL" \
  -e teamcity_admin_token="$TEAMCITY_ADMIN_TOKEN"
```

Remember: **Security is everyone's responsibility!** 🔐
