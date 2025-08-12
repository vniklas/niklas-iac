// Windows Virtual Machine Bicep Module
// Creates a Windows Server 2025 VM with cost-optimized settings

@description('Virtual Machine name')
param vmName string

@description('Azure region for the VM')
param location string

@description('VM size - using cost-effective B2s (2 vCPU, 4GB RAM)')
param vmSize string = 'Standard_B2s'

@description('Administrator username')
param adminUsername string

@description('Administrator password')
@secure()
param adminPassword string

@description('Subnet resource ID where VM will be deployed')
param subnetId string

@description('Resource tags')
param tags object

@description('Key Vault resource ID for storing VM password')
param keyVaultId string

// Variables
var nicName = 'nic-${vmName}'
var osDiskName = 'disk-${vmName}-os'

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    enableAcceleratedNetworking: false // Cost optimization
    enableIPForwarding: false
  }
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2025-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS' // Cost optimization
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}

// Store admin password in Key Vault
resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/vm-${vmName}-admin-password'
  properties: {
    value: adminPassword
    attributes: {
      enabled: true
    }
  }
}

// Azure Monitor Agent extension for monitoring
resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: virtualMachine
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

// Outputs
@description('Virtual Machine resource ID')
output vmId string = virtualMachine.id

@description('Virtual Machine name')
output vmName string = virtualMachine.name

@description('Network Interface resource ID')
output nicId string = networkInterface.id

@description('VM private IP address')
output privateIPAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

@description('VM system assigned identity principal ID')
output vmIdentityPrincipalId string = virtualMachine.identity.principalId
