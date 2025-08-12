#!/bin/bash

# Azure Landing Zone Deployment Script
# This script deploys the Azure Landing Zone using Bicep templates

set -e  # Exit on any error

# Configuration
RESOURCE_GROUP_NAME="rg-landingzone-prod-001"
LOCATION="eastus"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="parameters/main.parameters.json"
DEPLOYMENT_NAME="landingzone-deployment-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Azure Landing Zone Deployment${NC}"
echo "=================================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure. Starting login process...${NC}"
    az login
fi

# Display current subscription
CURRENT_SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}📋 Current subscription: ${CURRENT_SUBSCRIPTION}${NC}"

# Prompt for subscription change if needed
read -p "Do you want to change the subscription? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Available subscriptions:"
    az account list --query "[].{Name:name, SubscriptionId:id}" -o table
    read -p "Enter subscription ID: " SUBSCRIPTION_ID
    az account set --subscription "$SUBSCRIPTION_ID"
    echo -e "${GREEN}✅ Switched to subscription: $(az account show --query name -o tsv)${NC}"
fi

# Check if Bicep is installed
echo -e "${YELLOW}🔧 Checking Bicep installation...${NC}"
if ! az bicep version &> /dev/null; then
    echo -e "${YELLOW}⚠️  Bicep is not installed. Installing...${NC}"
    az bicep install
    echo -e "${GREEN}✅ Bicep installed successfully${NC}"
fi

# Create resource group if it doesn't exist
echo -e "${YELLOW}🏗️  Checking resource group...${NC}"
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Resource group '$RESOURCE_GROUP_NAME' does not exist. Creating...${NC}"
    az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
    echo -e "${GREEN}✅ Resource group created successfully${NC}"
else
    echo -e "${GREEN}✅ Resource group '$RESOURCE_GROUP_NAME' already exists${NC}"
fi

# Validate the template
echo -e "${YELLOW}🔍 Validating Bicep template...${NC}"
if az deployment group validate \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --output none; then
    echo -e "${GREEN}✅ Template validation successful${NC}"
else
    echo -e "${RED}❌ Template validation failed${NC}"
    exit 1
fi

# Deploy the template
echo -e "${YELLOW}🚀 Starting deployment...${NC}"
echo "Deployment name: $DEPLOYMENT_NAME"
echo "Resource group: $RESOURCE_GROUP_NAME"
echo "Template file: $TEMPLATE_FILE"
echo "Parameters file: $PARAMETERS_FILE"
echo

if az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --output table; then
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo
    
    # Show deployment outputs
    echo -e "${YELLOW}📋 Deployment Outputs:${NC}"
    az deployment group show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs \
        --output table
        
else
    echo -e "${RED}❌ Deployment failed${NC}"
    echo -e "${YELLOW}📋 Checking deployment status...${NC}"
    az deployment group show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.error \
        --output table
    exit 1
fi

echo
echo -e "${GREEN}✅ Azure Landing Zone deployment completed successfully!${NC}"
echo "=================================================="
