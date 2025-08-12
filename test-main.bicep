// Test Bicep file
targetScope = 'resourceGroup'

param location string = resourceGroup().location

// Deploy Log Analytics Workspace
module logAnalytics 'modules/monitoring/loganalytics.bicep' = {
  name: 'deploy-loganalytics'
  params: {
    logAnalyticsName: 'test-law-001'
    location: location
    tags: {}
  }
}

// Deploy Virtual Network
module virtualNetwork 'modules/networking/vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    vnetName: 'test-vnet-001'
    location: location
    vnetAddressSpace: '10.0.0.0/16'
    appSubnetAddressSpace: '10.0.1.0/24'
    dbSubnetAddressSpace: '10.0.2.0/24'
    mgmtSubnetAddressSpace: '10.0.3.0/24'
    bastionSubnetAddressSpace: '10.0.4.0/27'
    workloadName: 'test'
    environment: 'dev'
    tags: {}
    natGatewayId: ''
  }
}

output vnetId string = virtualNetwork.outputs.vnetId
