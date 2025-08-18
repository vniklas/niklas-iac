// ==============================================================================
// Azure Landing Zone Infrastructure as Code
// ==============================================================================

targetScope = 'resourceGroup'

// Parameters
@description('The primary location where resources will be deployed')
param location string = resourceGroup().location

@description('The workload name for resource naming')
param workloadName string

@description('The environment for resource naming (e.g., dev, test, prod)')
param environment string

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

@description('VM administrator username')
param vmAdminUsername string

@description('VM administrator password')
@secure()
param vmAdminPassword string

// Variables for consistent naming
var namingPrefix = '${workloadName}-${environment}'
var resourceTags = {
  Environment: environment
  Workload: workloadName
  ManagedBy: 'Bicep'
}

var vnetName = 'vnet-${namingPrefix}-001'
var keyVaultName = 'kv-${namingPrefix}-${uniqueString(resourceGroup().id)}'
var logAnalyticsName = 'law-${namingPrefix}-001'
var natGatewayName = 'natgw-${namingPrefix}-001'
var natPublicIpName = 'pip-natgw-${namingPrefix}-001'
var bastionPublicIpName = 'pip-bas-${namingPrefix}-001'
// Storage account names must be lowercase and <=24 chars; use a truncated unique suffix
var storageAccountName = toLower('st${workloadName}${environment}${substring(uniqueString(resourceGroup().id), 0, 8)}')
var eventHubNamespaceName = 'evhns-${namingPrefix}-001'
var eventHubName = 'evh-${namingPrefix}-messages-001'

// Create a user-assigned managed identity to be shared by resources (VM, apps)
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uai-${namingPrefix}-001'
  location: location
  tags: resourceTags
}

// Deploy NAT Gateway
module natGateway 'modules/networking/natgateway.bicep' = {
  name: 'deploy-natgateway'
  params: {
    natGatewayName: natGatewayName
    location: location
    tags: resourceTags
    publicIpName: natPublicIpName
  }
}

// Deploy Log Analytics Workspace
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

// Deploy Network Security Groups
module networkSecurityGroups 'modules/networking/nsg.bicep' = {
  name: 'deploy-nsgs'
  params: {
    location: location
    workloadName: workloadName
    environment: environment
    tags: resourceTags
  }
}

// Deploy Key Vault
module keyVault 'modules/security/keyvault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: resourceTags
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Deploy Storage Account
module storageAccount 'modules/storage/storageaccount.bicep' = {
  name: 'deploy-storageaccount'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: resourceTags
    sku: 'Standard_LRS'
    diagnosticsContainerName: 'diagnostics'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Deploy Azure Bastion
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

// Deploy Windows VM
module windowsVM 'modules/compute/vm-windows.bicep' = {
  name: 'deploy-windows-vm'
  params: {
    vmName: 'vm-${namingPrefix}-001'
    location: location
    tags: resourceTags
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    subnetId: virtualNetwork.outputs.mgmtSubnetId
    vmSize: 'Standard_B2s'
    userAssignedIdentityId: userAssignedIdentity.id
  }
}

// Deploy Event Hub (cheapest configuration for message receiving)
module eventHub 'modules/messaging/eventhub.bicep' = {
  name: 'deploy-eventhub'
  params: {
    eventHubNamespaceName: eventHubNamespaceName
    eventHubName: eventHubName
    location: location
    tags: resourceTags
    skuName: 'Basic' // Cheapest tier
    throughputUnits: 1 // Minimum and cheapest
    messageRetentionInDays: 1 // Minimum retention for cost optimization
    partitionCount: 2 // Good balance for basic messaging
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Deploy subscription-scoped policies to enforce allowed regions
module policyModule 'modules/security/policy.bicep' = {
  name: 'deploy-policy'
  scope: subscription()
  params: {
    allowedLocations: [
      'swedencentral'
    ]
    displayNamePrefix: 'lz-policy'
  }
}

// Outputs
output vnetId string = virtualNetwork.outputs.vnetId
output vnetName string = virtualNetwork.outputs.vnetName
output appSubnetId string = virtualNetwork.outputs.appSubnetId
output dbSubnetId string = virtualNetwork.outputs.dbSubnetId
output mgmtSubnetId string = virtualNetwork.outputs.mgmtSubnetId
output bastionSubnetId string = virtualNetwork.outputs.bastionSubnetId
output keyVaultName string = keyVault.outputs.keyVaultName
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
output bastionName string = bastion.outputs.bastionName
output vmName string = windowsVM.outputs.vmName
output storageAccountName string = storageAccount.outputs.storageAccountName
output storageAccountId string = storageAccount.outputs.storageAccountId
output diagnosticsContainerName string = storageAccount.outputs.diagnosticsContainerName
output primaryBlobEndpoint string = storageAccount.outputs.primaryBlobEndpoint
output eventHubNamespaceName string = eventHub.outputs.namespaceName
output eventHubName string = eventHub.outputs.eventHubName
output eventHubEndpoint string = eventHub.outputs.endpoint
output eventHubEstimatedCost string = eventHub.outputs.estimatedMonthlyCost
