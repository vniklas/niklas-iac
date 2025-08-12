// Network Security Groups Bicep Module
// Creates NSGs with baseline security rules for different subnet tiers

@description('Azure region for NSGs')
param location string

@description('Workload name for NSG naming')
param workloadName string

@description('Environment designation')
param environment string

@description('Resource tags')
param tags object

// Application Tier NSG
resource appNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-${workloadName}-app-${environment}-001'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          description: 'Allow HTTPS traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          description: 'Allow HTTP traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Database Tier NSG
resource dbNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-${workloadName}-db-${environment}-001'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSQLFromApp'
        properties: {
          description: 'Allow SQL traffic from application subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.0.1.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowMySQLFromApp'
        properties: {
          description: 'Allow MySQL traffic from application subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: '10.0.1.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Management Tier NSG
resource mgmtNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-${workloadName}-mgmt-${environment}-001'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowRDPFromBastion'
        properties: {
          description: 'Allow RDP from Azure Bastion subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '10.0.4.0/27'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 900
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowRDPFromCorpNet'
        properties: {
          description: 'Allow RDP from corporate network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '192.168.0.0/16'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSSHFromCorpNet'
        properties: {
          description: 'Allow SSH from corporate network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '192.168.0.0/16'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Outputs
@description('Application NSG resource ID')
output appNsgId string = appNsg.id

@description('Database NSG resource ID')
output dbNsgId string = dbNsg.id

@description('Management NSG resource ID')
output mgmtNsgId string = mgmtNsg.id

@description('Application NSG name')
output appNsgName string = appNsg.name

@description('Database NSG name')
output dbNsgName string = dbNsg.name

@description('Management NSG name')
output mgmtNsgName string = mgmtNsg.name
