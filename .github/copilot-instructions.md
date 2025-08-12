# Copilot Instructions for Azure Landing Zone

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This is an Azure Landing Zone project using Bicep Infrastructure as Code following Microsoft Cloud Adoption Framework (CAF) reference architecture.

## Project Guidelines

- Follow Microsoft Azure naming conventions and CAF best practices
- Use Bicep for all infrastructure definitions
- Implement proper resource tagging for governance
- Include security hardening measures
- Follow least privilege access principles
- Use Azure Policy and RBAC consistently
- Implement proper logging and monitoring
- Use parameter files for environment-specific configurations

## Key Components

- Virtual Network with proper subnetting
- Network Security Groups with security rules
- Resource Groups with consistent naming
- Azure Policy assignments
- RBAC role assignments
- Key Vault for secrets management
- Log Analytics workspace
- Application Gateway (if needed)
- Azure Firewall (if needed)

## Bicep Best Practices

- Use descriptive parameter and variable names
- Include proper descriptions for all parameters
- Use resource decorators for metadata
- Implement proper dependency management
- Use modules for reusable components
- Include outputs for important resource properties
