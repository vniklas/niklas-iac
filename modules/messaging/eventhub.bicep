// Event Hub Bicep Module
// Creates an Event Hub namespace and hub with the cheapest possible configuration

@description('Event Hub namespace name')
param eventHubNamespaceName string

@description('Event Hub name')
param eventHubName string

@description('Azure region for the Event Hub')
param location string

@description('Resource tags')
param tags object

@description('SKU tier for Event Hub - Basic is the cheapest option')
@allowed(['Basic', 'Standard', 'Premium'])
param skuName string = 'Basic'

@description('Throughput units for Basic/Standard tier (1 is minimum and cheapest)')
@minValue(1)
@maxValue(20)
param throughputUnits int = 1

@description('Message retention in days - 1 day is minimum for Basic tier')
@minValue(1)
@maxValue(7)
param messageRetentionInDays int = 1

@description('Partition count - affects scalability but not cost')
@minValue(1)
@maxValue(32)
param partitionCount int = 2

@description('Key Vault resource ID for storing connection strings')
param keyVaultId string

@description('Log Analytics workspace ID for monitoring')
param logAnalyticsWorkspaceId string

// Event Hub Namespace
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: eventHubNamespaceName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
    capacity: throughputUnits
  }
  properties: {
    isAutoInflateEnabled: false // Keep costs predictable
    maximumThroughputUnits: 0 // Must be 0 when auto-inflate is disabled
    kafkaEnabled: false // Not available in Basic tier anyway
  }
}

// Event Hub
resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: messageRetentionInDays
    partitionCount: partitionCount
    status: 'Active'
  }
}

// Note: Consumer groups are automatically managed in Basic tier
// The $Default consumer group is created automatically

// Send access policy for applications
resource sendPolicy 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' = {
  parent: eventHubNamespace
  name: 'SendPolicy'
  properties: {
    rights: ['Send']
  }
}

// Listen access policy for applications  
resource listenPolicy 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' = {
  parent: eventHubNamespace
  name: 'ListenPolicy'
  properties: {
    rights: ['Listen']
  }
}

// Manage access policy (for admin operations)
resource managePolicy 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' = {
  parent: eventHubNamespace
  name: 'ManagePolicy'
  properties: {
    rights: ['Manage', 'Listen', 'Send']
  }
}

// Diagnostic settings for monitoring
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'eventhub-diagnostics'
  scope: eventHubNamespace
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Store connection strings securely in Key Vault
resource sendConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/eventhub-send-connection-string'
  properties: {
    value: sendPolicy.listKeys().primaryConnectionString
    attributes: {
      enabled: true
    }
  }
}

resource listenConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/eventhub-listen-connection-string'
  properties: {
    value: listenPolicy.listKeys().primaryConnectionString
    attributes: {
      enabled: true
    }
  }
}

resource manageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/eventhub-manage-connection-string'
  properties: {
    value: managePolicy.listKeys().primaryConnectionString
    attributes: {
      enabled: true
    }
  }
}

// Outputs
@description('Event Hub namespace resource ID')
output namespaceId string = eventHubNamespace.id

@description('Event Hub namespace name')
output namespaceName string = eventHubNamespace.name

@description('Event Hub resource ID')
output eventHubId string = eventHub.id

@description('Event Hub name')
output eventHubName string = eventHub.name

@description('Event Hub send policy name (use with Key Vault to store connection string)')
output sendPolicyName string = sendPolicy.name

@description('Event Hub listen policy name (use with Key Vault to store connection string)')
output listenPolicyName string = listenPolicy.name

@description('Event Hub manage policy name (use with Key Vault to store connection string)')
output managePolicyName string = managePolicy.name

@description('Event Hub endpoint')
output endpoint string = eventHubNamespace.properties.serviceBusEndpoint

@description('Monthly cost estimate in USD (Basic tier with 1 TU: approximately $11/month)')
output estimatedMonthlyCost string = 'Approximately $${string(throughputUnits * 11)} USD/month (${throughputUnits} TU x $11/month/TU)'
