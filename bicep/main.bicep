targetScope = 'subscription'

@secure()
@description('The username of the admin user')
param adminUsername string

@secure()
@description('The password of the admin user')
param adminPassword string

@description('The location of the Azure resources')
param location string

@description('The name of the resource group')
param rgName string

var suffix = uniqueString(rg.id)

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module vnet 'modules/network/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vnet'
  params: {
    location: location 
    suffix: suffix
  }
}

module jumpbox 'modules/jumpbox/jumpbox.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'jumpbox'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    subnetId: vnet.outputs.subnetJumpboxId
  }
}


module monitoring 'modules/monitoring/monitoring.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'monitoring'
  params: {
    location: location
    suffix: suffix
  }
}

module storage 'modules/storage/storage.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storage'
  params: {
    location: location
    suffix: suffix
  }
}

module function 'modules/function/function.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'function'
  params: {
    appInsightName: monitoring.outputs.insightName
    location: location
    storageName: storage.outputs.storageAccountName
    suffix: suffix
  }
}

output functionName string = function.outputs.functionName