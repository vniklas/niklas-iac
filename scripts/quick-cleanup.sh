#!/bin/bash

# Simple Azure Resource Cleanup Script
# Fast and reliable cleanup for cost management

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}Simple Azure Cleanup${NC}"
    echo ""
    echo "Usage: $0 [action] [environment]"
    echo ""
    echo "ACTIONS:"
    echo "  stop-vms      - Stop VMs (saves compute costs)"
    echo "  deallocate    - Deallocate VMs (stops all compute billing)"
    echo "  delete-rg     - Delete entire resource group"
    echo "  list          - List resources quickly"
    echo ""
    echo "ENVIRONMENTS:"
    echo "  test   - rg-landingzone-test-001"
    echo "  dev    - rg-landingzone-dev-001"
    echo "  both   - Both environments"
    echo ""
    echo "Examples:"
    echo "  $0 stop-vms test"
    echo "  $0 deallocate dev"
    echo "  $0 delete-rg test"
    echo "  $0 list both"
}

get_rg() {
    case $1 in
        test) echo "rg-landingzone-test-001" ;;
        dev) echo "rg-landingzone-dev-001" ;;
        *) echo "" ;;
    esac
}

stop_vms() {
    local env=$1
    local rg=$(get_rg $env)
    
    if [[ -z "$rg" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🛑 Stopping VMs in $env environment ($rg)${NC}"
    
    # Quick check if RG exists
    if ! az group exists --name $rg 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Resource group $rg does not exist${NC}"
        return 0
    fi
    
    # Get VMs quickly
    local vms=$(az vm list -g $rg --query '[].name' -o tsv 2>/dev/null)
    
    if [[ -z "$vms" ]]; then
        echo -e "${YELLOW}ℹ️  No VMs found in $rg${NC}"
        return 0
    fi
    
    # Stop each VM
    while IFS= read -r vm; do
        if [[ -n "$vm" ]]; then
            echo -e "  🔄 Stopping VM: $vm"
            az vm stop -g $rg -n "$vm" --no-wait
        fi
    done <<< "$vms"
    
    echo -e "${GREEN}✅ VM stop commands sent for $env environment${NC}"
}

deallocate_vms() {
    local env=$1
    local rg=$(get_rg $env)
    
    if [[ -z "$rg" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        return 1
    fi
    
    echo -e "${BLUE}💸 Deallocating VMs in $env environment ($rg)${NC}"
    echo -e "${YELLOW}ℹ️  This stops ALL compute billing but releases public IPs${NC}"
    
    # Quick check if RG exists
    if ! az group exists --name $rg 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Resource group $rg does not exist${NC}"
        return 0
    fi
    
    # Get VMs quickly
    local vms=$(az vm list -g $rg --query '[].name' -o tsv 2>/dev/null)
    
    if [[ -z "$vms" ]]; then
        echo -e "${YELLOW}ℹ️  No VMs found in $rg${NC}"
        return 0
    fi
    
    # Deallocate each VM
    while IFS= read -r vm; do
        if [[ -n "$vm" ]]; then
            echo -e "  💸 Deallocating VM: $vm"
            az vm deallocate -g $rg -n "$vm" --no-wait
        fi
    done <<< "$vms"
    
    echo -e "${GREEN}✅ VM deallocate commands sent for $env environment${NC}"
}

delete_resource_group() {
    local env=$1
    local rg=$(get_rg $env)
    
    if [[ -z "$rg" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        return 1
    fi
    
    echo -e "${RED}💥 WARNING: This will permanently delete ALL resources in $rg${NC}"
    echo -e "${YELLOW}⚠️  This action cannot be undone!${NC}"
    read -p "Type 'DELETE' to confirm: " confirm
    
    if [[ "$confirm" != "DELETE" ]]; then
        echo -e "${YELLOW}❌ Cancelled by user${NC}"
        return 0
    fi
    
    echo -e "${BLUE}🗑️  Deleting resource group: $rg${NC}"
    az group delete --name $rg --yes --no-wait
    echo -e "${GREEN}✅ Deletion started for $rg${NC}"
}

list_resources() {
    local env=$1
    
    if [[ "$env" == "both" ]]; then
        list_resources "test"
        echo ""
        list_resources "dev"
        return
    fi
    
    local rg=$(get_rg $env)
    
    if [[ -z "$rg" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📋 Resources in $env environment ($rg):${NC}"
    
    if ! az group exists --name $rg 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Resource group does not exist${NC}"
        return 0
    fi
    
    # Quick resource count
    local count=$(az resource list -g $rg --query 'length(@)' -o tsv 2>/dev/null || echo "0")
    echo -e "  📦 Total resources: $count"
    
    # List VMs only (fastest check)
    local vms=$(az vm list -g $rg --query '[].name' -o tsv 2>/dev/null)
    if [[ -n "$vms" ]]; then
        echo -e "  💻 VMs found:"
        while IFS= read -r vm; do
            if [[ -n "$vm" ]]; then
                echo -e "    - $vm"
            fi
        done <<< "$vms"
    else
        echo -e "  💻 No VMs found"
    fi
}

# Main logic
ACTION=${1:-help}
ENVIRONMENT=${2:-}

case $ACTION in
    stop-vms)
        if [[ "$ENVIRONMENT" == "both" ]]; then
            stop_vms "test"
            stop_vms "dev"
        elif [[ -n "$ENVIRONMENT" ]]; then
            stop_vms "$ENVIRONMENT"
        else
            echo -e "${RED}❌ Environment required for stop-vms${NC}"
            show_help
            exit 1
        fi
        ;;
    deallocate)
        if [[ "$ENVIRONMENT" == "both" ]]; then
            deallocate_vms "test"
            deallocate_vms "dev"
        elif [[ -n "$ENVIRONMENT" ]]; then
            deallocate_vms "$ENVIRONMENT"
        else
            echo -e "${RED}❌ Environment required for deallocate${NC}"
            show_help
            exit 1
        fi
        ;;
    delete-rg)
        if [[ -n "$ENVIRONMENT" && "$ENVIRONMENT" != "both" ]]; then
            delete_resource_group "$ENVIRONMENT"
        else
            echo -e "${RED}❌ Specific environment required for delete-rg${NC}"
            show_help
            exit 1
        fi
        ;;
    list)
        if [[ -n "$ENVIRONMENT" ]]; then
            list_resources "$ENVIRONMENT"
        else
            list_resources "both"
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac
