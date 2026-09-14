param name string
param location string
param appServicePlanId string
param storageAccountName string
param receiptsStorageAccountName string
param receiptsContainerName string
param appInsightsConnectionString string
param serviceBusNamespaceName string
param serviceBusListenRuleName string
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource receiptsStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: receiptsStorageAccountName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusNamespaceName
}

resource listenRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' existing = {
  parent: serviceBusNamespace
  name: serviceBusListenRuleName
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
var receiptsStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${receiptsStorageAccount.name};AccountKey=${receiptsStorageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  kind: 'functionapp,linux'
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNET-ISOLATED|9.0'
      appSettings: [
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'dotnet-isolated' }
        { name: 'AzureWebJobsStorage', value: storageConnectionString }
        { name: 'BlobContainerName', value: receiptsContainerName }
        { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }
        { name: 'ApplicationInsightsAgent_EXTENSION_VERSION', value: '~3' }
        { name: 'ServiceBusConnection', value: listenRule.listKeys().primaryConnectionString }
        { name: 'ReceiptsStorageConnection', value: receiptsStorageConnectionString }
      ]
    }
  }
}

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output defaultHostname string = functionApp.properties.defaultHostName
