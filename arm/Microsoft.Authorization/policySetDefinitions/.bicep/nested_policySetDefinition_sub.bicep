targetScope = 'subscription'
param policySetDefinitionName string
param displayName string = ''
param policySetDescription string = ''
param metadata object = {}
param policyDefinitions array
param policyDefinitionGroups array = []
param parameters object = {}
param location string = deployment().location
param subscriptionId string = subscription().id

resource policySetDefinition 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: policySetDefinitionName
  location: location
  properties: {
    policyType: 'Custom'
    displayName: (empty(displayName) ? json('null') : displayName)
    description: (empty(policySetDescription) ? json('null') : policySetDescription)
    metadata: (empty(metadata) ? json('null') : metadata)
    parameters: (empty(parameters) ? json('null') : parameters)
    policyDefinitions: policyDefinitions
    policyDefinitionGroups: (empty(policyDefinitionGroups) ? [] : policyDefinitionGroups)
  }
}

output policySetDefinitionId string = subscriptionResourceId(subscriptionId, 'Microsoft.Authorization/policySetDefinitions', policySetDefinition.name)
