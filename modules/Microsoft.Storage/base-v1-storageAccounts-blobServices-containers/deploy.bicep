@maxLength(24)
@description('Conditional. The name of the parent Storage Account. Required if the template is used in a standalone deployment.')
param storageAccountName string

@description('Optional. Name of the blob service.')
param blobServicesName string = 'default'

@description('Required. The name of the storage container to deploy.')
param name string

@description('Optional. Name of the immutable policy.')
param immutabilityPolicyName string = 'default'

@allowed([
  'Container'
  'Blob'
  'None'
])
@description('Optional. Specifies whether data in the container may be accessed publicly and the level of access.')
param publicAccess string = 'None'

@description('Optional. Configure immutability policy.')
param immutabilityPolicyProperties object = {}

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

var enableReferencedModulesTelemetry = false

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName

  resource blobServices 'blobServices@2021-09-01' existing = {
    name: blobServicesName
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: name
  parent: storageAccount::blobServices
  properties: {
    publicAccess: publicAccess
  }
}

module immutabilityPolicy 'br/modules:microsoft.storage.base-v1-storageaccounts-blobservices-containers-immutabilitypolicies:0.0.1' = if (!empty(immutabilityPolicyProperties)) {
  name: immutabilityPolicyName
  params: {
    storageAccountName: storageAccount.name
    blobServicesName: storageAccount::blobServices.name
    containerName: container.name
    immutabilityPeriodSinceCreationInDays: contains(immutabilityPolicyProperties, 'immutabilityPeriodSinceCreationInDays') ? immutabilityPolicyProperties.immutabilityPeriodSinceCreationInDays : 365
    allowProtectedAppendWrites: contains(immutabilityPolicyProperties, 'allowProtectedAppendWrites') ? immutabilityPolicyProperties.allowProtectedAppendWrites : true
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}

@description('The name of the deployed container.')
output name string = container.name

@description('The resource ID of the deployed container.')
output resourceId string = container.id

@description('The resource group of the deployed container.')
output resourceGroupName string = resourceGroup().name