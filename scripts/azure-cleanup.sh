#!/bin/bash

# Quick Azure VM Cleanup Script
# This script provides easy commands to manage Azure costs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=""
ACTION=""

show_help() {
    echo -e "${BLUE}Azure Cost Management Script${NC}"
    echo ""
    echo "Usage: $0 [ENVIRONMENT] [ACTION]"
    echo ""
    echo "ENVIRONMENTS:"
    echo "  dev     - Development environment (rg-landingzone-dev-001)"
    echo "  test    - Test environment (rg-landingzone-test-001)"
    echo "  all     - Both environments"
    echo ""
    echo "ACTIONS:"
    echo "  stop          - Stop VMs (reduces compute costs, keeps storage)"
    echo "  deallocate    - Deallocate VMs (eliminates compute costs, keeps storage)"
    echo "  delete-vms    - Delete VMs permanently"
    echo "  delete-all    - Delete entire resource group"
    echo "  status        - Show current resource status"
    echo ""
    echo "Examples:"
    echo "  $0 dev stop              # Stop VMs in dev environment"
    echo "  $0 test deallocate       # Deallocate VMs in test environment"
    echo "  $0 all status            # Show status of all environments"
    echo "  $0 dev delete-all        # Delete entire dev environment"
    echo ""
}

get_resource_group() {
    case $1 in
        "dev")
            echo "rg-landingzone-dev-001"
            ;;
        "test")
            echo "rg-landingzone-test-001"
            ;;
        *)
            echo ""
            ;;
    esac
}

check_azure_login() {
    if ! az account show &>/dev/null; then
        echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Azure CLI authenticated${NC}"
}

show_costs_info() {
    echo -e "${YELLOW}💡 Cost Management Tips:${NC}"
    echo "• Stopped VMs: Compute charges stop, storage charges continue"
    echo "• Deallocated VMs: Compute charges stop, IP addresses released"
    echo "• Deleted VMs: All charges stop, data is permanently lost"
    echo "• Monitor costs: https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview"
    echo ""
}

show_environment_status() {
    local env=$1
    local rg=$(get_resource_group $env)
    
    if [[ -z "$rg" ]]; then
        return
    fi
    
    echo -e "${BLUE}📊 Environment: $env ($rg)${NC}"
    
    if ! az group exists --name $rg 2>/dev/null; then
        echo -e "  ${YELLOW}⚠️  Resource group does not exist${NC}"
        return
    fi
    
    # Count total resources
    local total_resources=$(az resource list --resource-group $rg --query 'length(@)' -o tsv 2>/dev/null || echo "0")
    echo -e "  📦 Total resources: $total_resources"
    
    # Check VMs
    local vms=$(az vm list --resource-group $rg --query '[].{Name:name, PowerState:powerState}' -o table 2>/dev/null || echo "")
    if [[ -n "$vms" && "$vms" != "[]" ]]; then
        echo -e "  💻 Virtual Machines:"
        az vm list --resource-group $rg --show-details --query '[].{Name:name, PowerState:powerState, Size:hardwareProfile.vmSize}' -o table 2>/dev/null || echo "    None found"
    else
        echo -e "  💻 Virtual Machines: None"
    fi
    
    # Check expensive resources
    local bastion_count=$(az network bastion list --resource-group $rg --query 'length(@)' -o tsv 2>/dev/null || echo "0")
    local natgw_count=$(az network nat gateway list --resource-group $rg --query 'length(@)' -o tsv 2>/dev/null || echo "0")
    local pip_count=$(az network public-ip list --resource-group $rg --query 'length(@)' -o tsv 2>/dev/null || echo "0")
    
    echo -e "  🔗 High-cost resources:"
    echo -e "    • Bastion hosts: $bastion_count"
    echo -e "    • NAT gateways: $natgw_count" 
    echo -e "    • Public IPs: $pip_count"
    echo ""
}

stop_vms() {
    local env=$1
    local deallocate=$2
    local rg=$(get_resource_group $env)
    
    if [[ -z "$rg" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        return 1
    fi
    
    if ! az group exists --name $rg; then
        echo -e "${YELLOW}⚠️  Resource group $rg does not exist${NC}"
        return 0
    fi
    
    local vms=$(az vm list --resource-group $rg --query '[].name' -o tsv)
    
    if [[ -z "$vms" ]]; then
        echo -e "${YELLOW}ℹ️  No VMs found in $env environment${NC}"
        return 0
    fi
    
    local action_word="Stopping"
    local action_cmd="stop"
    
    if [[ "$deallocate" == "true" ]]; then
        action_word="Deallocating"
        action_cmd="deallocate"
    fi
    
    echo -e "${BLUE}🛑 $action_word VMs in $env environment...${NC}"
    
    for vm in $vms; do
        echo -e "  $action_word VM: $vm"
        az vm $action_cmd --resource-group $rg --name $vm --no-wait
    done
    
    echo -e "${GREEN}✅ VM $action_cmd commands issued for $env environment${NC}"
}

delete_vms() {
    local env=$1
    local rg=$(get_resource_group $env)
    
    if [[ -z "$rg" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        return 1
    fi
    
    echo -e "${RED}⚠️  WARNING: This will permanently delete all VMs in $env environment!${NC}"
    read -p "Type 'DELETE' to confirm: " confirmation
    
    if [[ "$confirmation" != "DELETE" ]]; then
        echo -e "${YELLOW}❌ Deletion cancelled${NC}"
        return 0
    fi
    
    if ! az group exists --name $rg; then
        echo -e "${YELLOW}⚠️  Resource group $rg does not exist${NC}"
        return 0
    fi
    
    echo -e "${RED}🗑️  Deleting VMs in $env environment...${NC}"
    
    az vm list --resource-group $rg --query '[].id' -o tsv | \
        xargs -r az vm delete --yes --no-wait --ids
    
    echo -e "${GREEN}✅ VM deletion initiated for $env environment${NC}"
}

delete_resource_group() {
    local env=$1
    local rg=$(get_resource_group $env)
    
    if [[ -z "$rg" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        return 1
    fi
    
    echo -e "${RED}⚠️  WARNING: This will permanently delete ALL resources in $env environment!${NC}"
    echo -e "${RED}    Resource Group: $rg${NC}"
    read -p "Type 'DELETE' to confirm: " confirmation
    
    if [[ "$confirmation" != "DELETE" ]]; then
        echo -e "${YELLOW}❌ Deletion cancelled${NC}"
        return 0
    fi
    
    if ! az group exists --name $rg; then
        echo -e "${YELLOW}⚠️  Resource group $rg does not exist${NC}"
        return 0
    fi
    
    echo -e "${RED}🗑️  Deleting resource group $rg...${NC}"
    az group delete --name $rg --yes --no-wait
    
    echo -e "${GREEN}✅ Resource group deletion initiated for $env environment${NC}"
}

# Main script logic
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

ENVIRONMENT=$1
ACTION=$2

if [[ "$ENVIRONMENT" == "--help" || "$ENVIRONMENT" == "-h" ]]; then
    show_help
    exit 0
fi

check_azure_login
show_costs_info

case $ACTION in
    "status")
        if [[ "$ENVIRONMENT" == "all" ]]; then
            show_environment_status "dev"
            show_environment_status "test"
        else
            show_environment_status $ENVIRONMENT
        fi
        ;;
    "stop")
        if [[ "$ENVIRONMENT" == "all" ]]; then
            stop_vms "dev" "false"
            stop_vms "test" "false"
        else
            stop_vms $ENVIRONMENT "false"
        fi
        ;;
    "deallocate")
        if [[ "$ENVIRONMENT" == "all" ]]; then
            stop_vms "dev" "true"
            stop_vms "test" "true"
        else
            stop_vms $ENVIRONMENT "true"
        fi
        ;;
    "delete-vms")
        if [[ "$ENVIRONMENT" == "all" ]]; then
            delete_vms "dev"
            delete_vms "test"
        else
            delete_vms $ENVIRONMENT
        fi
        ;;
    "delete-all")
        if [[ "$ENVIRONMENT" == "all" ]]; then
            delete_resource_group "dev"
            delete_resource_group "test"
        else
            delete_resource_group $ENVIRONMENT
        fi
        ;;
    "")
        echo -e "${RED}❌ Please specify an action${NC}"
        show_help
        exit 1
        ;;
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac
