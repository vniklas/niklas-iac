# 🌿 Branching Strategy and Repository Guardrails

## Overview

This repository implements a comprehensive branching strategy with repository guardrails to ensure safe, controlled deployments to Azure environments.

## 🌳 Branch Structure

```
main (production)
├── develop (integration)
└── feature/* (development)
```

### Branch Purposes

- **`main`**: Production-ready code. Deploys to production environment
- **`develop`**: Integration branch. Deploys to dev environment  
- **`feature/*`**: Feature development. Deploys to dev environment for testing

## 🔄 Workflow Process

### 1. Feature Development
```bash
# Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Make changes and commit
git add .
git commit -m "feat: add your feature"
git push origin feature/your-feature-name
```

### 2. Feature Integration
```bash
# Create PR from feature/* to develop
# This triggers:
# - Bicep validation
# - Security scanning
# - Deployment to dev environment
```

### 3. Test Environment Validation
```bash
# Create PR from develop to main
# This triggers:
# - All validation checks
# - Deployment to test environment
# - What-If analysis for production
# - Integration tests
```

### 4. Production Deployment
```bash
# Merge PR to main (after approvals)
# This triggers:
# - Production deployment workflow
# - Comprehensive verification
# - Security validation
```

## 🔒 Branch Protection Rules

### Main Branch Protection
- ✅ Requires 2 approving reviews
- ✅ Dismisses stale reviews when new commits are pushed
- ✅ Requires code owner review
- ✅ Requires last push approval
- ✅ Enforces admin compliance
- ✅ Required status checks:
  - Validate Bicep Templates
  - Security Scan
  - What-If Analysis

### Develop Branch Protection
- ✅ Requires 1 approving review
- ✅ Dismisses stale reviews
- ✅ Required status checks:
  - Validate Bicep Templates
  - Security Scan

## 🚀 Deployment Strategy

| Branch | Environment | Trigger | Approval Required |
|--------|-------------|---------|-------------------|
| `feature/*` | dev | Push | No |
| `develop` | dev | Push | No |
| `develop→main` PR | test | PR opened | No |
| `main` | production | Merge to main | Yes |

## 🛡️ Security Features

### Automated Security Checks
- **Vulnerability Alerts**: Enabled for dependencies
- **Automated Security Fixes**: Enabled for known vulnerabilities
- **Secret Scanning**: Built into workflows
- **Infrastructure Security**: Bicep template security validation

### Access Controls
- **CODEOWNERS**: Required reviews from designated owners
- **Environment Protection**: Production environment requires manual approval
- **Least Privilege**: Minimal required permissions for workflows

## 📋 Quality Gates

### Pre-merge Validation
1. **Syntax Validation**: All Bicep templates must compile
2. **Security Scan**: No hardcoded secrets or insecure configurations
3. **What-If Analysis**: Preview of changes before deployment
4. **Cost Estimation**: Projected infrastructure costs
5. **Integration Tests**: Basic connectivity and functionality tests

### Post-deployment Verification
1. **Resource Verification**: All expected resources deployed
2. **Connectivity Tests**: Network and service connectivity
3. **Security Validation**: Access policies and configurations
4. **Monitoring Setup**: Logging and alerting configured

## 🔧 Setup Instructions

### 1. Configure Branch Protection
```bash
# Run the setup script
chmod +x scripts/setup-guardrails.sh
./scripts/setup-guardrails.sh
```

### 2. Create Required Branches
```bash
# Create develop branch
git checkout -b develop
git push origin develop
```

### 3. Configure GitHub Environments

In GitHub Settings → Environments, create:

#### Dev Environment
- **Protection Rules**: None (auto-deploy)
- **Secrets**: Same as repository secrets

#### Test Environment  
- **Protection Rules**: None (auto-deploy on PR)
- **Secrets**: Same as repository secrets

#### Production Environment
- **Protection Rules**: 
  - Required reviewers (add your team)
  - Wait timer: 5 minutes
- **Secrets**: Production-specific secrets

## 📖 Usage Examples

### Creating a New Feature
```bash
# Start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/add-event-hub

# Make changes, test locally
# Commit and push
git add .
git commit -m "feat: add Event Hub with Basic tier configuration"
git push origin feature/add-event-hub

# Create PR to develop
gh pr create --base develop --title "Add Event Hub configuration" --body "Adds Event Hub with cost-optimized Basic tier"
```

### Promoting to Test
```bash
# After feature is merged to develop
git checkout develop
git pull origin develop

# Create PR to main for test deployment
gh pr create --base main --title "Deploy Event Hub to production" --body "Ready for production deployment after successful test validation"
```

### Emergency Hotfix
```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix

# Make fix and create PR directly to main
gh pr create --base main --title "HOTFIX: Critical security fix" --body "Emergency fix for security vulnerability"
```

## 🎯 Best Practices

### Commit Messages
Use conventional commits format:
- `feat:` - New features
- `fix:` - Bug fixes  
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Test additions/changes
- `chore:` - Maintenance tasks

### PR Guidelines
- **Title**: Clear, descriptive summary
- **Description**: What changes and why
- **Testing**: How it was tested
- **Screenshots**: For UI changes
- **Breaking Changes**: Clearly documented

### Code Review Focus
- **Security**: Access policies, secrets management
- **Cost Optimization**: Resource sizing and configurations
- **Maintainability**: Clear naming, documentation
- **Compliance**: Tagging, naming conventions
- **Monitoring**: Logging and alerting setup

## 🚨 Emergency Procedures

### Rollback Production
```bash
# Via Azure CLI (manual)
az deployment group create \
  --resource-group rg-landingzone-prod-001 \
  --template-file previous-working-template.bicep \
  --parameters @parameters/main.parameters.json

# Via GitHub Actions (recommended)
# Revert the commit and push to main
git revert <commit-hash>
git push origin main
```

### Hotfix Process
1. Create hotfix branch from main
2. Make minimal necessary changes
3. Create PR with "HOTFIX" label
4. Get emergency approval
5. Deploy immediately after merge

## 📊 Monitoring and Alerting

### Key Metrics to Monitor
- **Deployment Success Rate**: Track workflow failures
- **Lead Time**: Time from commit to production
- **Change Failure Rate**: Percentage of deployments causing issues
- **Recovery Time**: Time to resolve deployment issues

### Alerts Setup
- Failed deployments
- Security scan failures
- Cost threshold exceeded
- Resource health issues

---

## 🆘 Support

For questions or issues with the branching strategy:
1. Check the workflow runs in GitHub Actions
2. Review the repository protection settings
3. Consult this documentation
4. Contact the infrastructure team

Remember: **Better safe than sorry** - when in doubt, ask for review!
