// NAT Gateway Bicep Module
// Deploys a NAT Gateway and Public IP, and outputs their IDs

@description('NAT Gateway name')
param natGatewayName string

@description('Azure region for NAT Gateway')
param location string

@description('Resource tags')
param tags object

@description('Public IP name for NAT Gateway')
param publicIpName string

@description('Idle timeout in minutes (default: 4, max: 120)')
@minValue(4)
@maxValue(120)
param idleTimeoutInMinutes int = 4

// Public IP for NAT Gateway
resource natPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
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

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
    idleTimeoutInMinutes: idleTimeoutInMinutes
  }
  tags: tags
}

// Outputs
@description('NAT Gateway resource ID')
output natGatewayId string = natGateway.id

@description('Public IP resource ID')
output publicIpId string = natPublicIp.id
