// Azure Landing Zone - Main Bicep Template
// This template creates a landing zone with VM and Bastion

targetScope = 'resourceGroup'

// Parameters
@description('The Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Environment designation (e.g., dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string = 'test'

@description('Project or workload name for resource naming')
@minLength(2)
@maxLength(10)
param workloadName string = 'lz'

@description('Virtual Network address space')
param vnetAddressSpace string = '10.0.0.0/16'

@description('Application subnet address space')
param appSubnetAddressSpace string = '10.0.1.0/24'

@description('Database subnet address space')
param dbSubnetAddressSpace string = '10.0.2.0/24'

@description('Management subnet address space')
param mgmtSubnetAddressSpace string = '10.0.3.0/24'

@description('Bastion subnet address space')
param bastionSubnetAddressSpace string = '10.0.4.0/27'

@description('VM admin username')
param vmAdminUsername string = 'azureuser'

@description('VM admin password')
@secure()
param vmAdminPassword string

@description('VM size')
param vmSize string = 'Standard_B2s'

@description('Tags to be applied to all resources')
param resourceTags object = {
  Environment: environment
  Project: workloadName
  ManagedBy: 'Bicep'
  CostCenter: 'IT'
  Owner: 'DevOps Team'
}

// Variables
var namingPrefix = '${workloadName}-${environment}'
var vnetName = 'vnet-${namingPrefix}-001'
var keyVaultName = 'kv-${namingPrefix}-${uniqueString(resourceGroup().id)}'
var logAnalyticsName = 'law-${namingPrefix}-001'
var natGatewayName = 'natgw-${namingPrefix}-001'
var natPublicIpName = 'pip-natgw-${namingPrefix}-001'
var bastionPublicIpName = 'pip-bas-${namingPrefix}-001'

// Deploy NAT Gateway (if not exists)
module natGateway 'modules/networking/natgateway.bicep' = {
  name: 'deploy-natgateway'
  params: {
    natGatewayName: natGatewayName
    location: location
    tags: resourceTags
    publicIpName: natPublicIpName
  }
}

// Deploy Log Analytics Workspace (if not exists)
module logAnalytics 'modules/monitoring/loganalytics.bicep' = {
  name: 'deploy-loganalytics'
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    tags: resourceTags
  }
}

// Deploy Virtual Network with Bastion subnet
module virtualNetwork 'modules/networking/vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    vnetName: vnetName
    location: location
    vnetAddressSpace: vnetAddressSpace
    appSubnetAddressSpace: appSubnetAddressSpace
    dbSubnetAddressSpace: dbSubnetAddressSpace
    mgmtSubnetAddressSpace: mgmtSubnetAddressSpace
    bastionSubnetAddressSpace: bastionSubnetAddressSpace
    workloadName: workloadName
    environment: environment
    tags: resourceTags
    natGatewayId: natGateway.outputs.natGatewayId
  }
}

// Deploy Network Security Groups (if not exists)
module networkSecurityGroups 'modules/networking/nsg.bicep' = {
  name: 'deploy-nsgs'
  params: {
    location: location
    workloadName: workloadName
    environment: environment
    tags: resourceTags
  }
}

// Deploy Key Vault (if not exists)
module keyVault 'modules/security/keyvault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: resourceTags
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Deploy Azure Bastion (NEW)
module bastion 'modules/networking/bastion.bicep' = {
  name: 'deploy-bastion'
  params: {
    bastionName: 'bas-${namingPrefix}-001'
    location: location
    tags: resourceTags
    bastionSubnetId: virtualNetwork.outputs.bastionSubnetId
    publicIpName: bastionPublicIpName
  }
}

// Deploy Windows VM (NEW)
module windowsVM 'modules/compute/vm-windows.bicep' = {
  name: 'deploy-windows-vm'
  params: {
    vmName: 'vm-${namingPrefix}-mgmt-001'
    location: location
    tags: resourceTags
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    vmSize: vmSize
    subnetId: virtualNetwork.outputs.mgmtSubnetId
    keyVaultId: keyVault.outputs.keyVaultId
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Outputs
@description('Virtual Network resource ID')
output vnetId string = virtualNetwork.outputs.vnetId

@description('Virtual Network name')
output vnetName string = virtualNetwork.outputs.vnetName

@description('Bastion subnet resource ID')
output bastionSubnetId string = virtualNetwork.outputs.bastionSubnetId

@description('Management subnet resource ID')
output mgmtSubnetId string = virtualNetwork.outputs.mgmtSubnetId

@description('Key Vault resource ID')
output keyVaultId string = keyVault.outputs.keyVaultId

@description('Azure Bastion resource ID')
output bastionId string = bastion.outputs.bastionId

@description('Windows VM resource ID')
output windowsVmId string = windowsVM.outputs.vmId

@description('Windows VM name')
output windowsVmName string = windowsVM.outputs.vmName
