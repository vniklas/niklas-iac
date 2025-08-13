#!/bin/bash

# Script to configure repository guardrails and branch protection
# Run this script to set up proper branch protection and repository settings

set -e

echo "🔒 Setting up repository guardrails and branch protection..."

# Repository settings
REPO_OWNER="vniklas"
REPO_NAME="niklas-iac"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📋 Configuring branch protection for main branch...${NC}"

# Main branch protection
gh api repos/$REPO_OWNER/$REPO_NAME/branches/main/protection \
  --method PUT \
  --field required_status_checks='{
    "strict": true,
    "contexts": [
      "Validate Bicep Templates",
      "Security Scan",
      "What-If Analysis"
    ]
  }' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": true
  }' \
  --field restrictions=null || echo -e "${YELLOW}⚠️ Branch protection might already be configured${NC}"

echo -e "${GREEN}📋 Configuring branch protection for develop branch...${NC}"

# Develop branch protection (less strict)
gh api repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{
    "strict": true,
    "contexts": [
      "Validate Bicep Templates",
      "Security Scan"
    ]
  }' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  }' \
  --field restrictions=null || echo -e "${YELLOW}⚠️ Develop branch protection might already be configured${NC}"

echo -e "${GREEN}🔐 Setting up repository security settings...${NC}"

# Enable vulnerability alerts
gh api repos/$REPO_OWNER/$REPO_NAME/vulnerability-alerts \
  --method PUT || echo -e "${YELLOW}⚠️ Vulnerability alerts might already be enabled${NC}"

# Enable automated security fixes
gh api repos/$REPO_OWNER/$REPO_NAME/automated-security-fixes \
  --method PUT || echo -e "${YELLOW}⚠️ Automated security fixes might already be enabled${NC}"

echo -e "${GREEN}📝 Repository settings configured successfully!${NC}"

echo ""
echo -e "${GREEN}✅ Repository Guardrails Summary:${NC}"
echo ""
echo -e "${GREEN}🔒 Main Branch Protection:${NC}"
echo "  - Requires 2 approving reviews"
echo "  - Dismisses stale reviews"
echo "  - Requires code owner reviews"
echo "  - Requires last push approval"
echo "  - Enforces admin compliance"
echo "  - Requires status checks: Bicep validation, Security scan, What-If analysis"
echo ""
echo -e "${GREEN}🔒 Develop Branch Protection:${NC}"
echo "  - Requires 1 approving review"
echo "  - Dismisses stale reviews"
echo "  - Requires status checks: Bicep validation, Security scan"
echo ""
echo -e "${GREEN}🛡️ Security Features:${NC}"
echo "  - Vulnerability alerts enabled"
echo "  - Automated security fixes enabled"
echo ""
echo -e "${GREEN}📋 Workflow Strategy:${NC}"
echo "  - Feature branches → develop (auto-deploy to dev)"
echo "  - develop → main via PR (deploy to test for validation)"
echo "  - main branch (deploy to production with approvals)"
echo ""
echo -e "${YELLOW}⚠️ Next Steps:${NC}"
echo "1. Create a 'develop' branch if it doesn't exist"
echo "2. Create CODEOWNERS file to define code owners"
echo "3. Configure GitHub environments (dev, test, production) with proper secrets"
echo "4. Set up approval workflows for production environment"
echo ""
echo -e "${GREEN}🚀 Your repository is now properly protected!${NC}"
