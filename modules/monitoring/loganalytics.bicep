// Log Analytics Workspace Bicep Module
// Creates a Log Analytics workspace for centralized logging and monitoring

@description('Log Analytics workspace name')
param logAnalyticsName string

@description('Azure region for Log Analytics workspace')
param location string

@description('Resource tags')
param tags object

@description('Log Analytics workspace SKU')
@allowed(['Free', 'Standard', 'Premium', 'PerNode', 'PerGB2018', 'Standalone'])
param sku string = 'PerGB2018'

@description('Data retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Common Log Analytics Solutions
resource securityCenterSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Security(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'Security(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Security'
    promotionCode: ''
  }
}

resource updatesSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Updates(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'Updates(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Updates'
    promotionCode: ''
  }
}

resource vmInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'VMInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
  }
}

// Saved Queries for common monitoring scenarios
resource savedQuery1 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalyticsWorkspace
  name: 'failed-logins'
  properties: {
    displayName: 'Failed Login Attempts'
    category: 'Security'
    query: 'SecurityEvent | where EventID == 4625 | summarize count() by Account, Computer | order by count_ desc'
    version: 1
  }
}

resource savedQuery2 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalyticsWorkspace
  name: 'resource-usage'
  properties: {
    displayName: 'Resource Usage Summary'
    category: 'Performance'
    query: 'Perf | where CounterName == "% Processor Time" | summarize avg(CounterValue) by Computer | order by avg_CounterValue desc'
    version: 1
  }
}

// Outputs
@description('Log Analytics workspace resource ID')
output workspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics workspace name')
output workspaceName string = logAnalyticsWorkspace.name

@description('Log Analytics workspace customer ID')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
