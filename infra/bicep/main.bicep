targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'centralus'

@description('Project name prefix')
param projectName string = 'order-system'

@description('Application environment')
param environment string = 'dev'

// Short unique suffix for resources that require globally-unique names
var resourceToken = toLower(take(uniqueString(subscription().subscriptionId, projectName, environment), 6))
var resourceGroupName = 'rg-${projectName}-${environment}'
var commonTags = {
  course: 'serverless'
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'log-analytics'
  scope: rg
  params: {
    name: 'log-${projectName}-${environment}'
    location: location
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    location: location
    mainStorageAccountName: toLower(take('st${take(replace(projectName, '-', ''), 8)}${environment}${resourceToken}', 24))
    fileStorageAccountName: toLower(take('stf${take(replace(projectName, '-', ''), 8)}${environment}${resourceToken}', 24))
  }
}

module serviceBus 'modules/service-bus.bicep' = {
  name: 'service-bus'
  scope: rg
  params: {
    location: location
    namespaceName: 'sb-${projectName}-${environment}-${resourceToken}'
  }
}

module cosmos 'modules/cosmosdb.bicep' = {
  name: 'cosmosdb'
  scope: rg
  params: {
    location: location
    accountName: toLower('cosmos-${projectName}-${environment}-${resourceToken}')
    environment: environment
    projectName: projectName
  }
}

module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'app-service-plan'
  scope: rg
  params: {
    location: location
    name: 'asp-${projectName}-${environment}'
  }
}

module appInsightsApi 'modules/app-insights.bicep' = {
  name: 'app-insights-api'
  scope: rg
  params: {
    location: location
    name: 'appi-${projectName}-api-${environment}'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: union(commonTags, { func: '${projectName}-api-${environment}' })
  }
}

module appInsightsProcessor 'modules/app-insights.bicep' = {
  name: 'app-insights-order-processor'
  scope: rg
  params: {
    location: location
    name: 'appi-${projectName}-order-processor-${environment}'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

module appInsightsTrackerLogger 'modules/app-insights.bicep' = {
  name: 'app-insights-order-tracker-logger'
  scope: rg
  params: {
    location: location
    name: 'appi-${projectName}-order-tracker-logger-${environment}'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

module orderApiFunction 'modules/function-app-order-api.bicep' = {
  name: 'function-app-order-api'
  scope: rg
  params: {
    location: location
    name: 'func-${projectName}-api-${environment}-${resourceToken}'
    appServicePlanId: appServicePlan.outputs.planId
    storageAccountName: storage.outputs.mainStorageAccountName
    appInsightsConnectionString: appInsightsApi.outputs.connectionString
    serviceBusNamespaceName: serviceBus.outputs.namespaceName
    serviceBusSendRuleName: serviceBus.outputs.sendRuleName
    queueName: serviceBus.outputs.queueName
    tags: union(commonTags, { func: '${projectName}-api-${environment}' })
  }
}

module orderProcessorFunction 'modules/function-app-order-processor.bicep' = {
  name: 'function-app-order-processor'
  scope: rg
  params: {
    location: location
    name: 'func-${projectName}-order-processor-${environment}-${resourceToken}'
    appServicePlanId: appServicePlan.outputs.planId
    storageAccountName: storage.outputs.mainStorageAccountName
    receiptsStorageAccountName: storage.outputs.fileStorageAccountName
    receiptsContainerName: storage.outputs.receiptsContainerName
    appInsightsConnectionString: appInsightsProcessor.outputs.connectionString
    serviceBusNamespaceName: serviceBus.outputs.namespaceName
    serviceBusListenRuleName: serviceBus.outputs.listenRuleName
    tags: union(commonTags, { src: 'bicep' })
  }
}

module orderTrackerLoggerFunction 'modules/function-app-order-tracker-logger.bicep' = {
  name: 'function-app-order-tracker-logger'
  scope: rg
  params: {
    location: location
    name: 'func-${projectName}-order-tracker-logger-${environment}-${resourceToken}'
    appServicePlanId: appServicePlan.outputs.planId
    storageAccountName: storage.outputs.mainStorageAccountName
    appInsightsConnectionString: appInsightsTrackerLogger.outputs.connectionString
    cosmosAccountName: cosmos.outputs.accountName
    cosmosDatabaseName: cosmos.outputs.databaseName
    cosmosContainerName: cosmos.outputs.containerName
  }
}

module orderApiDiagnostics 'modules/diagnostic-settings.bicep' = {
  name: 'order-api-diagnostics'
  scope: rg
  params: {
    name: 'func-${projectName}-api-${environment}-diag'
    functionAppName: orderApiFunction.outputs.functionAppName
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

module eventGrid 'modules/event-grid.bicep' = {
  name: 'event-grid'
  scope: rg
  params: {
    fileStorageAccountName: storage.outputs.fileStorageAccountName
    functionAppName: orderTrackerLoggerFunction.outputs.functionAppName
    functionName: 'OrderTrackerLogger'
  }
}

output resourceGroupName string = rg.name
output orderApiFunctionUrl string = orderApiFunction.outputs.defaultHostname
