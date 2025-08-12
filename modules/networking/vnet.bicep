// Virtual Network Bicep Module
// Creates VNet with multiple subnets including Bastion subnet

@description('Virtual Network name')
param vnetName string

@description('Azure region for VNet')
param location string

@description('Virtual Network address space')
param vnetAddressSpace string

@description('Application subnet address space')
param appSubnetAddressSpace string

@description('Database subnet address space')
param dbSubnetAddressSpace string

@description('Management subnet address space')
param mgmtSubnetAddressSpace string

@description('Bastion subnet address space (must be /27 or larger)')
param bastionSubnetAddressSpace string

@description('Workload name for resource naming')
param workloadName string

@description('Environment for resource naming')
param environment string

@description('Resource tags')
param tags object

@description('NAT Gateway resource ID')
param natGatewayId string

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'snet-${workloadName}-app-${environment}-001'
        properties: {
          addressPrefix: appSubnetAddressSpace
          natGateway: {
            id: natGatewayId
          }
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'nsg-${workloadName}-app-${environment}-001')
          }
        }
      }
      {
        name: 'snet-${workloadName}-db-${environment}-001'
        properties: {
          addressPrefix: dbSubnetAddressSpace
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'nsg-${workloadName}-db-${environment}-001')
          }
        }
      }
      {
        name: 'snet-${workloadName}-mgmt-${environment}-001'
        properties: {
          addressPrefix: mgmtSubnetAddressSpace
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'nsg-${workloadName}-mgmt-${environment}-001')
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetAddressSpace
        }
      }
    ]
  }
}

// Outputs
output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output appSubnetId string = virtualNetwork.properties.subnets[0].id
output dbSubnetId string = virtualNetwork.properties.subnets[1].id
output mgmtSubnetId string = virtualNetwork.properties.subnets[2].id
output bastionSubnetId string = virtualNetwork.properties.subnets[3].id
