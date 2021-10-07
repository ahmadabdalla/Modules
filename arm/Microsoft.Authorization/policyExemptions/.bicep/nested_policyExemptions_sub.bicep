targetScope = 'subscription'

param policyExemptionName string
param displayName string = ''
param policyExemptionDescription string = ''
param metadata object = {}
param exemptionCategory string = 'Mitigated'
param policyAssignmentId string
param policyDefinitionReferenceIds array = []
param expiresOn string = ''
param subscriptionId string = subscription().subscriptionId
param location string = deployment().location

resource policyExemption 'Microsoft.Authorization/policyExemptions@2020-07-01-preview' = {
  name: policyExemptionName
  location: location
  properties: {
    displayName: (empty(displayName) ? json('null') : displayName)
    description: (empty(policyExemptionDescription) ? json('null') : policyExemptionDescription)
    metadata: (empty(metadata) ? json('null') : metadata)
    exemptionCategory: exemptionCategory
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: (empty(policyDefinitionReferenceIds) ? [] : policyDefinitionReferenceIds)
    expiresOn: (empty(expiresOn) ? json('null') : expiresOn)
  }
}

output policyExemptionId string =   subscriptionResourceId(subscriptionId,'Microsoft.Authorization/policyExemptions',policyExemption.name)
output policyExemptionScope string = subscription().id
