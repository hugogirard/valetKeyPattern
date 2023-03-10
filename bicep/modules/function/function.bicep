param location string
param suffix string
param appInsightName string
param storageFunctionName string
param storagePicturesName string
param subnetId string

var appServiceName = 'asp-function-${suffix}'

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightName
}

resource storageFunction 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageFunctionName
}

resource storagePicture 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storagePicturesName
}


resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServiceName
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 100    
  }
}

resource function 'Microsoft.Web/sites@2022-03-01' = {
  name: 'func-${suffix}'
  location: location
  kind: 'functionapp'  
  properties: {
    httpsOnly: true
    serverFarmId: serverFarm.id    
    virtualNetworkSubnetId: subnetId
    siteConfig: {
      netFrameworkVersion: 'v6.0'
      vnetRouteAllEnabled: true
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageFunction.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageFunction.listKeys().keys[0].value}'
        }
        {
          name: 'PicturesStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storagePicture.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storagePicture.listKeys().keys[0].value}'          
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageFunction.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageFunction.listKeys().keys[0].value}'
        }       
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'funcshare'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }    
      ]
    }
  }
}


output functionName string = function.name
