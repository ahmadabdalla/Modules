targetScope = 'managementGroup'

param policyExemptionName string
param displayName string = ''
param policyExemptionDescription string = ''
param metadata object = {}
param exemptionCategory string = 'Mitigated'
param policyAssignmentId string
param policyDefinitionReferenceIds array = []
param expiresOn string = ''
param managementGroupId string
param location string = deployment().location

var policyExemptionName_var = toLower(replace(policyExemptionName, ' ', '-'))

resource policyExemption 'Microsoft.Authorization/policyExemptions@2020-07-01-preview' = {
  name: policyExemptionName_var
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

output policyExemptionName string = policyExemption.name
output policyExemptionId string =   extensionResourceId(tenantResourceId('Microsoft.Management/managementGroups',managementGroupId),'Microsoft.Authorization/policyExemptions',policyExemption.name)
output policyExemptionScope string = tenantResourceId('Microsoft.Management/managementGroups',managementGroupId)
