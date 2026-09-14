// One-time subscription-scope deployment: creates the RG so a narrower RG-scoped service connection can be created afterward.
targetScope = 'subscription'

@description('Azure region for the resource group')
param location string = 'centralus'

@description('Project name prefix')
param projectName string = 'order-system'

@description('Application environment')
param environment string = 'dev'

var commonTags = {
  course: 'serverless'
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${projectName}-${environment}'
  location: location
  tags: commonTags
}

output resourceGroupName string = rg.name
