param location string
param mainStorageAccountName string
param fileStorageAccountName string
param receiptsContainerName string = 'receipts'

// Runtime storage shared by all function apps
resource mainStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: mainStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// File storage for order receipts, source of the Event Grid BlobCreated trigger
resource fileStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: fileStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: fileStorage
  name: 'default'
}

resource receiptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: receiptsContainerName
  properties: {
    publicAccess: 'None'
  }
}

output mainStorageAccountName string = mainStorage.name
output fileStorageAccountName string = fileStorage.name
output fileStorageAccountId string = fileStorage.id
output receiptsContainerName string = receiptsContainer.name
