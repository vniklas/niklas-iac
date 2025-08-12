// Azure Bastion Bicep Module
// Creates Azure Bastion with Basic SKU for cost optimization

@description('Bastion Host name')
param bastionName string

@description('Azure region for Bastion')
param location string

@description('Public IP name for Bastion')
param publicIpName string

@description('Bastion subnet resource ID (must be named AzureBastionSubnet)')
param bastionSubnetId string

@description('Resource tags')
param tags object

// Public IP for Bastion (Standard SKU required)
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

// Azure Bastion Host with Basic SKU (cheapest option)
resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Basic' // Cheapest SKU
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
    // Basic SKU limitations - these features are not available
    // enableFileCopy: false (not available in Basic)
    // enableIpConnect: false (not available in Basic)
    // enableShareableLink: false (not available in Basic)
    // enableTunneling: false (not available in Basic)
  }
}

// Outputs
@description('Bastion Host resource ID')
output bastionId string = bastionHost.id

@description('Bastion Host name')
output bastionName string = bastionHost.name

@description('Public IP resource ID')
output publicIpId string = bastionPublicIp.id

@description('Bastion Public IP address')
output publicIpAddress string = bastionPublicIp.properties.ipAddress
