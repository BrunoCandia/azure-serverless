param fileStorageAccountName string
param functionAppName string
param functionName string = 'OrderTrackerLogger'
param subscriptionName string = 'file-uploaded-subscription'

resource fileStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: fileStorageAccountName
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: functionAppName
}

resource eventSubscription 'Microsoft.EventGrid/eventSubscriptions@2022-06-15' = {
  name: subscriptionName
  scope: fileStorageAccount
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: '${functionApp.id}/functions/${functionName}'
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
    retryPolicy: {
      maxDeliveryAttempts: 5
      eventTimeToLiveInMinutes: 1440
    }
  }
}
