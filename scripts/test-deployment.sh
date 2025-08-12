#!/bin/bash
# Azure Landing Zone Deployment Test Script
# This script performs comprehensive testing before and after deployment

set -e  # Exit on any error

# Configuration variables
RESOURCE_GROUP="rg-landingzone-test-001"
LOCATION="swedencentral"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="parameters/main.parameters.test.json"
DEPLOYMENT_NAME="test-deployment-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        exit 1
    fi
    
    # Check if user is logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login'"
        exit 1
    fi
    
    # Check if Bicep is available
    if ! az bicep version &> /dev/null; then
        print_error "Bicep is not available. Please install Bicep"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to validate Bicep syntax
validate_bicep_syntax() {
    print_status "Validating Bicep syntax..."
    
    if az bicep build --file "$TEMPLATE_FILE" --stdout > /dev/null; then
        print_success "Bicep syntax validation passed"
    else
        print_error "Bicep syntax validation failed"
        exit 1
    fi
}

# Function to create test resource group
create_test_resource_group() {
    print_status "Creating test resource group: $RESOURCE_GROUP"
    
    if az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none; then
        print_success "Test resource group created successfully"
    else
        print_error "Failed to create test resource group"
        exit 1
    fi
}

# Function to validate deployment template
validate_deployment() {
    print_status "Validating deployment template..."
    
    if az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$PARAMETERS_FILE" \
        --output none; then
        print_success "Deployment validation passed"
    else
        print_error "Deployment validation failed"
        return 1
    fi
}

# Function to perform what-if analysis
what_if_deployment() {
    print_status "Performing what-if analysis..."
    
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$PARAMETERS_FILE" \
        --name "$DEPLOYMENT_NAME"
}

# Function to deploy resources
deploy_resources() {
    print_status "Deploying resources..."
    
    if az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$PARAMETERS_FILE" \
        --name "$DEPLOYMENT_NAME" \
        --output table; then
        print_success "Deployment completed successfully"
    else
        print_error "Deployment failed"
        return 1
    fi
}

# Function to test deployed resources
test_deployed_resources() {
    print_status "Testing deployed resources..."
    
    # Get deployment outputs
    local outputs=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query 'properties.outputs' \
        --output json)
    
    # Test VNet connectivity
    local vnet_name=$(echo "$outputs" | jq -r '.vnetName.value')
    if az network vnet show --resource-group "$RESOURCE_GROUP" --name "$vnet_name" --output none 2>/dev/null; then
        print_success "VNet '$vnet_name' is accessible"
    else
        print_error "VNet '$vnet_name' is not accessible"
    fi
    
    # Test Key Vault accessibility
    local kv_name=$(echo "$outputs" | jq -r '.keyVaultName.value')
    if az keyvault show --name "$kv_name" --output none 2>/dev/null; then
        print_success "Key Vault '$kv_name' is accessible"
    else
        print_error "Key Vault '$kv_name' is not accessible"
    fi
    
    # Test Log Analytics workspace
    local law_name=$(echo "$outputs" | jq -r '.logAnalyticsWorkspaceName.value')
    if az monitor log-analytics workspace show --resource-group "$RESOURCE_GROUP" --workspace-name "$law_name" --output none 2>/dev/null; then
        print_success "Log Analytics workspace '$law_name' is accessible"
    else
        print_error "Log Analytics workspace '$law_name' is not accessible"
    fi
}

# Function to cleanup test resources
cleanup_test_resources() {
    print_status "Cleaning up test resources..."
    
    read -p "Do you want to delete the test resource group '$RESOURCE_GROUP'? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if az group delete --name "$RESOURCE_GROUP" --yes --no-wait; then
            print_success "Test resource group deletion initiated"
        else
            print_error "Failed to delete test resource group"
        fi
    else
        print_warning "Test resource group '$RESOURCE_GROUP' was not deleted"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --validate-only    Only validate the template without deploying"
    echo "  --deploy          Deploy the resources after validation"
    echo "  --cleanup         Cleanup test resources after deployment"
    echo "  --help            Show this help message"
}

# Main execution
main() {
    local validate_only=false
    local deploy=false
    local cleanup=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate-only)
                validate_only=true
                shift
                ;;
            --deploy)
                deploy=true
                shift
                ;;
            --cleanup)
                cleanup=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # If no options provided, show usage
    if [[ "$validate_only" == false && "$deploy" == false && "$cleanup" == false ]]; then
        show_usage
        exit 1
    fi
    
    print_status "Starting Azure Landing Zone deployment test..."
    
    # Run prerequisite checks
    check_prerequisites
    
    # Validate Bicep syntax
    validate_bicep_syntax
    
    if [[ "$validate_only" == true || "$deploy" == true ]]; then
        # Create test resource group
        create_test_resource_group
        
        # Validate deployment
        if ! validate_deployment; then
            print_error "Validation failed. Exiting."
            cleanup_test_resources
            exit 1
        fi
        
        # Perform what-if analysis
        what_if_deployment
    fi
    
    if [[ "$deploy" == true ]]; then
        # Deploy resources
        if deploy_resources; then
            # Test deployed resources
            test_deployed_resources
        else
            print_error "Deployment failed"
            cleanup_test_resources
            exit 1
        fi
    fi
    
    if [[ "$cleanup" == true ]]; then
        cleanup_test_resources
    fi
    
    print_success "Test script completed successfully!"
}

# Run main function with all arguments
main "$@"
