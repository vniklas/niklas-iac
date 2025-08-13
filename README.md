# Azure Landing Zone Infrastructure as Code

[![Deploy Azure Landing Zone](https://github.com/vniklas/niklas-iac/actions/workflows/azure-deploy.yml/badge.svg)](https://github.com/vniklas/niklas-iac/actions/workflows/azure-deploy.yml)

This repository contains Bicep templates for deploying a comprehensive Azure Landing Zone with GitHub Actions CI/CD automation.

## 🏗️ Architecture Overview

The Azure Landing Zone includes:

- **🌐 Networking**: Virtual Network with segmented subnets, NAT Gateway, Network Security Groups
- **🔐 Security**: Azure Key Vault, Network Security Groups, Azure Bastion for secure access
- **💻 Compute**: Windows Server 2025 Virtual Machines with monitoring
- **📊 Monitoring**: Log Analytics Workspace with centralized diagnostic logging
- **💾 Storage**: Storage Account with diagnostics container and monitoring
- Log Analytics workspace for monitoring
- Azure Policy assignments for governance
- RBAC role assignments for access control

## Prerequisites

- Azure CLI installed and configured
- Azure PowerShell (optional)
- Bicep CLI installed
- Appropriate Azure subscription permissions

## Quick Start

1. **Clone and configure parameters:**
   ```bash
   # Copy and edit the parameters file
   cp parameters/main.parameters.example.json parameters/main.parameters.json
   # Edit the parameters file with your specific values
   ```

2. **Deploy the landing zone:**
   ```bash
   # Login to Azure
   az login

   # Set subscription
   az account set --subscription "your-subscription-id"

   # Deploy to target resource group
   az deployment group create \
     --resource-group "rg-landingzone-prod-001" \
     --template-file main.bicep \
     --parameters @parameters/main.parameters.json
   ```

3. **Validate deployment:**
   ```bash
   # Test the deployment without making changes
   az deployment group validate \
     --resource-group "rg-landingzone-prod-001" \
     --template-file main.bicep \
     --parameters @parameters/main.parameters.json
   ```

## Architecture

The landing zone follows a hub-and-spoke network topology with:

### Network Architecture
- **Hub VNet**: Central connectivity point
- **Application Subnet**: For application workloads
- **Database Subnet**: For database workloads
- **Management Subnet**: For management resources

### Security
- Network Security Groups with default deny rules
- Azure Key Vault for secret management
- Azure Policy for compliance enforcement
- RBAC for access control

### Monitoring
- Log Analytics workspace for centralized logging
- Application Insights for application monitoring

## File Structure

```
├── main.bicep                          # Main Bicep template
├── modules/
│   ├── networking/
│   │   ├── vnet.bicep                  # Virtual Network module
│   │   └── nsg.bicep                   # Network Security Group module
│   ├── security/
│   │   ├── keyvault.bicep              # Key Vault module
│   │   └── policy.bicep                # Azure Policy module
│   └── monitoring/
│       └── loganalytics.bicep          # Log Analytics module
├── parameters/
│   ├── main.parameters.json            # Production parameters
│   └── main.parameters.example.json    # Example parameters
└── scripts/
    ├── deploy.ps1                      # PowerShell deployment script
    └── deploy.sh                       # Bash deployment script
```

## Customization

### Environment-specific Parameters
Edit the parameters file to customize:
- Naming conventions
- Network address spaces
- Security policies
- Resource locations

### Adding Components
To add new components:
1. Create a new module in the `modules/` directory
2. Reference it in `main.bicep`
3. Add required parameters

## Best Practices Implemented

- **Naming Convention**: Follows Azure naming conventions
- **Tagging Strategy**: Consistent resource tagging
- **Security**: Least privilege access and security hardening
- **Monitoring**: Comprehensive logging and monitoring
- **Governance**: Azure Policy and RBAC implementation

## Contributing

1. Follow the established naming conventions
2. Include proper parameter descriptions
3. Add appropriate tags to all resources
4. Test deployments before committing

## Support

For questions or issues:
- Review the Azure CAF documentation
- Check Azure Bicep best practices
- Validate Bicep syntax using `az bicep build`
