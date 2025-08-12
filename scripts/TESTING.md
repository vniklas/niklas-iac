# Azure Landing Zone Testing Guide

This directory contains comprehensive testing scripts and configurations for the Azure Landing Zone deployment.

## Test Files

### Scripts
- `test-deployment.sh` - Main testing script for validation and deployment
- `deploy.sh` - Original deployment script
- `deploy.ps1` - PowerShell deployment script

### Parameters
- `main.parameters.test.json` - Test environment parameters
- `main.parameters.json` - Production parameters
- `main.parameters.example.json` - Example parameter file

## Testing Workflow

### 1. Prerequisites
Ensure you have:
- Azure CLI installed and logged in (`az login`)
- Bicep CLI available (`az bicep version`)
- Appropriate Azure permissions
- jq installed for JSON parsing (optional but recommended)

### 2. Validation Only
To validate the template without deploying:
```bash
chmod +x scripts/test-deployment.sh
./scripts/test-deployment.sh --validate-only
```

### 3. Full Deployment Test
To deploy and test resources:
```bash
./scripts/test-deployment.sh --deploy
```

### 4. Cleanup Test Resources
To clean up after testing:
```bash
./scripts/test-deployment.sh --cleanup
```

### 5. Complete Test Cycle
To run validation, deployment, and cleanup:
```bash
./scripts/test-deployment.sh --deploy --cleanup
```

## What the Test Script Does

### Pre-deployment Checks
1. **Prerequisites Validation**
   - Checks Azure CLI installation
   - Verifies user authentication
   - Confirms Bicep availability

2. **Bicep Syntax Validation**
   - Builds the Bicep template
   - Checks for syntax errors

3. **Template Validation**
   - Uses `az deployment group validate`
   - Checks parameter compatibility
   - Validates resource dependencies

4. **What-If Analysis**
   - Shows what resources will be created
   - Displays configuration changes
   - Helps identify potential issues

### Post-deployment Tests
1. **Resource Accessibility**
   - Tests VNet connectivity
   - Validates Key Vault access
   - Checks Log Analytics workspace

2. **Configuration Verification**
   - Verifies resource properties
   - Checks subnet associations
   - Validates NAT Gateway attachment

## Test Environment Configuration

The test uses a separate resource group (`rg-landingzone-test-001`) and environment-specific parameters to avoid conflicts with production resources.

### Key Differences from Production
- Environment: `test` instead of `prod`
- Resource naming includes `test` suffix
- Separate resource group for isolation
- Additional tags for identification

## Troubleshooting

### Common Issues
1. **Authentication Errors**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Permission Issues**
   - Ensure you have Contributor role on the subscription
   - Check resource provider registrations

3. **Naming Conflicts**
   - Key Vault names must be globally unique
   - Use different workload names if conflicts occur

4. **Region Availability**
   - Verify all resources are available in the target region
   - Some SKUs may not be available in all regions

### Debug Mode
To run with verbose output:
```bash
az deployment group create --debug [other-parameters]
```

## Security Considerations

- Test resources use the same security configurations as production
- Key Vault access policies are applied
- Network Security Groups are configured
- All resources are tagged for identification

## Cost Management

- Test deployments use the same SKUs as production
- Monitor costs in the Azure portal
- Delete test resources promptly after testing
- Consider using Azure DevTest pricing if available

## CI/CD Integration

This test script can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Test Azure Deployment
  run: |
    chmod +x scripts/test-deployment.sh
    ./scripts/test-deployment.sh --validate-only
```
