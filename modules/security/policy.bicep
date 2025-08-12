// Azure Policy Bicep Module
// Deploys baseline Azure policies for governance and compliance

targetScope = 'subscription'

@description('Workload name for policy naming')
param workloadName string

@description('Environment designation')
param environment string

// Variables
var allowedLocations = [
  'eastus'
  'eastus2'
  'westus2'
  'westeurope'
  'northeurope'
]

// Built-in policy definition IDs
var requiredTagsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62'
var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
var storageSecureTransferPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'

// Policy Assignment: Required Tags
resource requiredTagsAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'assign-required-tags-${workloadName}'
  properties: {
    displayName: 'Require specific tags on resources'
    description: 'Enforces required tags on all resources'
    policyDefinitionId: requiredTagsPolicyId
    parameters: {
      tagName: {
        value: 'Environment'
      }
      tagValue: {
        value: environment
      }
    }
    enforcementMode: 'Default'
  }
}

// Policy Assignment: Allowed Locations
resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'assign-allowed-locations-${workloadName}'
  properties: {
    displayName: 'Allowed locations for resources'
    description: 'Restricts resource deployment to approved Azure regions'
    policyDefinitionId: allowedLocationsPolicyId
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
    enforcementMode: 'Default'
  }
}

// Policy Assignment: Storage Secure Transfer
resource storageSecureTransferAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'assign-storage-secure-${workloadName}'
  properties: {
    displayName: 'Secure transfer to storage accounts should be enabled'
    description: 'Ensures that storage accounts require secure transfer (HTTPS)'
    policyDefinitionId: storageSecureTransferPolicyId
    enforcementMode: 'Default'
  }
}

// Custom Policy Definition: Naming Convention
resource namingConventionPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'naming-convention-${workloadName}'
  properties: {
    displayName: 'Enforce naming convention for ${workloadName}'
    description: 'Ensures resources follow the organization naming convention'
    policyType: 'Custom'
    mode: 'All'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            in: [
              'Microsoft.Compute/virtualMachines'
              'Microsoft.Storage/storageAccounts'
              'Microsoft.Network/virtualNetworks'
            ]
          }
          {
            not: {
              field: 'name'
              like: '*-${environment}-*'
            }
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Policy Assignment: Naming Convention
resource namingConventionAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'assign-naming-${workloadName}'
  properties: {
    displayName: 'Enforce naming convention'
    description: 'Enforces organizational naming conventions on resources'
    policyDefinitionId: namingConventionPolicy.id
    enforcementMode: 'Default'
  }
}

// Outputs
@description('Required tags policy assignment ID')
output requiredTagsAssignmentId string = requiredTagsAssignment.id

@description('Allowed locations policy assignment ID')
output allowedLocationsAssignmentId string = allowedLocationsAssignment.id

@description('Storage secure transfer policy assignment ID')
output storageSecureTransferAssignmentId string = storageSecureTransferAssignment.id

@description('Naming convention policy definition ID')
output namingConventionPolicyId string = namingConventionPolicy.id

@description('Naming convention policy assignment ID')
output namingConventionAssignmentId string = namingConventionAssignment.id
