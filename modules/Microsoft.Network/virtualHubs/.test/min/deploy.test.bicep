targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(80)
param resourceGroupName string = 'ms.network.virtualHub-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'nvhmin'

// =========== //
// Deployments //
// =========== //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module resourceGroupResources 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-nestedDependencies'
  params: {
    virtualWANName: 'dep-<<namePrefix>>-vw-${serviceShort}'
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name)}-test-${serviceShort}'
  params: {
    enableDefaultTelemetry: enableDefaultTelemetry
    name: '<<namePrefix>>-${serviceShort}'
    addressPrefix: '10.0.0.0/16'
    virtualWanId: resourceGroupResources.outputs.virtualWWANResourceId
  }
}
