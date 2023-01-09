targetScope = 'managementGroup'

@sys.description('Required. Specifies the name of the policy remediation.')
param name string

@sys.description('Optional. The remediation failure threshold settings. A number between 0.0 to 1.0 representing the percentage failure threshold. The remediation will fail if the percentage of failed remediation operations (i.e. failed deployments) exceeds this threshold. 0 means that the remediation will stop after the first failure. 1 means that the remediation will not stop even if all deployments fail.')
param failureThresholdPercentage string = '1'

@sys.description('Optional. The filters that will be applied to determine which resources to remediate.')
param filtersLocations array = []

@sys.description('Optional. Determines how many resources to remediate at any given time. Can be used to increase or reduce the pace of the remediation. Can be between 1-30. Higher values will cause the remediation to complete more quickly, but increase the risk of throttling. If not provided, the default parallel deployments value is used.')
@minValue(1)
@maxValue(30)
param parallelDeployments int = 10

@sys.description('Optional. Determines the max number of resources that can be remediated by the remediation job. Can be between 1-50000. If not provided, the default resource count is used.')
@minValue(1)
@maxValue(50000)
param resourceCount int = 500

@sys.description('Required. The way resources to remediate are discovered. Defaults to ExistingNonCompliant if not specified.')
@allowed([
  'ExistingNonCompliant'
  'ReEvaluateCompliance'
])
param resourceDiscoveryMode string = 'ExistingNonCompliant'

@sys.description('Required. The resource ID of the policy assignment that should be remediated.')
param policyAssignmentId string

@sys.description('Optional. The policy definition reference ID of the individual definition that should be remediated. Required when the policy assignment being remediated assigns a policy set definition.')
param policyDefinitionReferenceId string = ''

@sys.description('Optional. The target scope for the remediation. The name of the management group for the policy assignment. If not provided, will use the current scope for deployment.')
param managementGroupId string = managementGroup().name

@sys.description('Optional. The target scope for the remediation. The subscription ID of the subscription for the policy assignment.')
param subscriptionId string = ''

@sys.description('Optional. The target scope for the remediation. The name of the resource group for the policy assignment.')
param resourceGroupName string = ''

@sys.description('Optional. Location deployment metadata.')
param location string = deployment().location

@sys.description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

var enableReferencedModulesTelemetry = false

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, location)}'
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

module remediation_mg 'managementGroup/deploy.bicep' = if (empty(subscriptionId) && empty(resourceGroupName)) {
  name: '${uniqueString(deployment().name, location)}-Remediation-MG-Module'
  scope: managementGroup(managementGroupId)
  params: {
    enableDefaultTelemetry: enableReferencedModulesTelemetry
    name: name
    location: location
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceId: policyDefinitionReferenceId
    //filtersLocations: filtersLocations
    resourceCount: resourceCount
    resourceDiscoveryMode: resourceDiscoveryMode
    parallelDeployments: parallelDeployments
    failureThresholdPercentage: failureThresholdPercentage
  }
}

module remediation_sub 'subscription/deploy.bicep' = if (!empty(subscriptionId) && empty(resourceGroupName)) {
  name: '${uniqueString(deployment().name, location)}-Remediation-Sub-Module'
  scope: subscription(subscriptionId)
  params: {
    enableDefaultTelemetry: enableReferencedModulesTelemetry
    name: name
    location: location
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceId: policyDefinitionReferenceId
    //filtersLocations: filtersLocations
    resourceCount: resourceCount
    resourceDiscoveryMode: resourceDiscoveryMode
    parallelDeployments: parallelDeployments
    failureThresholdPercentage: failureThresholdPercentage
  }
}

module remediation_rg 'resourceGroup/deploy.bicep' = if (!empty(resourceGroupName) && !empty(subscriptionId)) {
  name: '${uniqueString(deployment().name, location)}-Remediation-RG-Module'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    enableDefaultTelemetry: enableReferencedModulesTelemetry
    name: name
    location: location
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceId: policyDefinitionReferenceId
    //filtersLocations: filtersLocations
    resourceCount: resourceCount
    resourceDiscoveryMode: resourceDiscoveryMode
    parallelDeployments: parallelDeployments
    failureThresholdPercentage: failureThresholdPercentage
  }
}

@sys.description('The name of the remediation.')
output name string = empty(subscriptionId) && empty(resourceGroupName) ? remediation_mg.outputs.name : (!empty(subscriptionId) && empty(resourceGroupName) ? remediation_sub.outputs.name : remediation_rg.outputs.name)

@description('The resource ID of the remediation.')
output resourceId string = empty(subscriptionId) && empty(resourceGroupName) ? remediation_mg.outputs.resourceId : (!empty(subscriptionId) && empty(resourceGroupName) ? remediation_sub.outputs.resourceId : remediation_rg.outputs.resourceId)

@sys.description('The location the resource was deployed into.')
output location string = empty(subscriptionId) && empty(resourceGroupName) ? remediation_mg.outputs.location : (!empty(subscriptionId) && empty(resourceGroupName) ? remediation_sub.outputs.location : remediation_rg.outputs.location)
