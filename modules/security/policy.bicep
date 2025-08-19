targetScope = 'subscription'

@description('Allowed Azure locations for this subscription')
param allowedLocations array = []

@description('Display name prefix for the policy definition and assignment')
param displayNamePrefix string = 'lz-policy'

// Policy definition: deny resources deployed outside allowed locations
resource allowedLocationsPolicyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: '${displayNamePrefix}-allowed-locations'
  properties: {
    displayName: 'Allowed locations for Landing Zone'
    description: 'Deny creation of resources outside the allowed locations list'
    mode: 'All'
    parameters: {
      allowedLocations: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed locations'
          description: 'The list of allowed Azure locations.'
        }
      }
    }
    policyRule: {
      if: {
        not: {
          field: 'location'
          in: '[parameters(\'allowedLocations\')]'
        }
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Policy assignment at subscription scope
resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: '${displayNamePrefix}-allowed-locations-assignment'
  properties: {
    displayName: 'Enforce Allowed Locations for Landing Zone'
    description: 'Assigns Allowed Locations policy for the subscription to restrict deployments to approved regions.'
    policyDefinitionId: allowedLocationsPolicyDef.id
    parameters: {
      allowedLocations: {
        value: allowedLocations
      }
    }
  }
}
