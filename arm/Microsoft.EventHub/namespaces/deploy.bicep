@description('Optional. The name of the EventHub namespace. If no name is provided, then unique name will be created.')
@maxLength(50)
param name string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. EventHub Plan sku name')
@allowed([
  'Basic'
  'Standard'
])
param skuName string = 'Standard'

@description('Optional. Event Hub Plan scale-out capacity of the resource')
@minValue(1)
@maxValue(20)
param skuCapacity int = 1

@description('Optional. Switch to make the Event Hub Namespace zone redundant.')
param zoneRedundant bool = false

@description('Optional. Switch to enable the Auto Inflate feature of Event Hub.')
param isAutoInflateEnabled bool = false

@description('Optional. Upper limit of throughput units when AutoInflate is enabled, value should be within 0 to 20 throughput units.')
@minValue(0)
@maxValue(20)
param maximumThroughputUnits int = 1

@description('Optional. Authorization Rules for the Event Hub namespace')
param authorizationRules array = [
  {
    name: 'RootManageSharedAccessKey'
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
]

@description('Optional. Configuration Details for private endpoints.')
param privateEndpoints array = []

@description('Optional. Service endpoint object information')
param networkAcls object = {}

@description('Optional. Virtual Network Id to lock down the Event Hub.')
param vNetId string = ''

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource identifier of the Diagnostic Storage Account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource identifier of Log Analytics.')
param workspaceId string = ''

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered')
param cuaId string = ''

@description('Generated. Do not provide a value! This date value is used to generate a SAS token to access the modules.')
param baseTime string = utcNow('u')

@description('Optional. The event hubs to deploy into this namespace')
param eventHubs array = []

@description('Optional. The disaster recovery config for this namespace')
param disasterRecoveryConfig object = {}

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'ArchiveLogs'
  'OperationalLogs'
  'KafkaCoordinatorLogs'
  'KafkaUserErrorLogs'
  'EventHubVNetConnectionEvent'
  'CustomerManagedKeyUserLogs'
  'AutoScaleLogs'
])
param logsToEnable array = [
  'ArchiveLogs'
  'OperationalLogs'
  'KafkaCoordinatorLogs'
  'KafkaUserErrorLogs'
  'EventHubVNetConnectionEvent'
  'CustomerManagedKeyUserLogs'
  'AutoScaleLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

var maxNameLength = 50
var uniqueEventHubNamespaceUntrim = uniqueString('EventHub Namespace${baseTime}')
var uniqueEventHubNamespace = length(uniqueEventHubNamespaceUntrim) > maxNameLength ? substring(uniqueEventHubNamespaceUntrim, 0, maxNameLength) : uniqueEventHubNamespaceUntrim
var name_var = empty(name) ? uniqueEventHubNamespace : name
var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', name_var, defaultSASKeyName)
var maximumThroughputUnits_var = !isAutoInflateEnabled ? 0 : maximumThroughputUnits
var virtualNetworkRules = [for index in range(0, (empty(networkAcls) ? 0 : length(networkAcls.virtualNetworkRules))): {
  id: '${vNetId}/subnets/${networkAcls.virtualNetworkRules[index].subnet}'
}]
var networkAcls_var = {
  bypass: !empty(networkAcls) ? networkAcls.bypass : null
  defaultAction: !empty(networkAcls) ? networkAcls.defaultAction : null
  virtualNetworkRules: !empty(networkAcls) ? virtualNetworkRules : null
  ipRules: !empty(networkAcls) ? (length(networkAcls.ipRules) > 0 ? networkAcls.ipRules : null) : null
}

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: name_var
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
    capacity: skuCapacity
  }
  properties: {
    zoneRedundant: zoneRedundant
    isAutoInflateEnabled: isAutoInflateEnabled
    maximumThroughputUnits: maximumThroughputUnits_var
    networkAcls: !empty(networkAcls) ? networkAcls_var : null
  }
}

resource eventHubNamespace_lock 'Microsoft.Authorization/locks@2016-09-01' = if (lock != 'NotSpecified') {
  name: '${eventHubNamespace.name}-${lock}-lock'
  properties: {
    level: lock
    notes: (lock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: eventHubNamespace
}

resource eventHubNamespace_diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(workspaceId))) {
  name: '${eventHubNamespace.name}-diagnosticSettings'
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(workspaceId) ? workspaceId : null
    metrics: !empty(diagnosticStorageAccountId) || !empty(workspaceId) ? diagnosticsMetrics : null
    logs: !empty(diagnosticStorageAccountId) || !empty(workspaceId) ? diagnosticsLogs : null
  }
  scope: eventHubNamespace
}

module eventHubNamespace_eventHubs 'eventhubs/deploy.bicep' = [for (eventHub, index) in eventHubs: {
  name: '${uniqueString(deployment().name, location)}-eventHub-${index}'
  params: {
    namespaceName: eventHubNamespace.name
    name: eventHub.name
    authorizationRules: contains(eventHub, 'authorizationRules') ? eventHub.authorizationRules : [
      {
        name: 'RootManageSharedAccessKey'
        properties: {
          rights: [
            'Listen'
            'Manage'
            'Send'
          ]
        }
      }
    ]
    captureDescriptionDestinationArchiveNameFormat: contains(eventHub, 'captureDescriptionDestinationArchiveNameFormat') ? eventHub.captureDescriptionDestinationArchiveNameFormat : '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
    captureDescriptionDestinationBlobContainer: contains(eventHub, 'captureDescriptionDestinationBlobContainer') ? eventHub.captureDescriptionDestinationBlobContainer : ''
    captureDescriptionDestinationName: contains(eventHub, 'captureDescriptionDestinationName') ? eventHub.captureDescriptionDestinationName : 'EventHubArchive.AzureBlockBlob'
    captureDescriptionDestinationStorageAccountResourceId: contains(eventHub, 'captureDescriptionDestinationStorageAccountResourceId') ? eventHub.captureDescriptionDestinationStorageAccountResourceId : ''
    captureDescriptionEnabled: contains(eventHub, 'captureDescriptionEnabled') ? eventHub.captureDescriptionEnabled : false
    captureDescriptionEncoding: contains(eventHub, 'captureDescriptionEncoding') ? eventHub.captureDescriptionEncoding : 'Avro'
    captureDescriptionIntervalInSeconds: contains(eventHub, 'captureDescriptionIntervalInSeconds') ? eventHub.captureDescriptionIntervalInSeconds : 300
    captureDescriptionSizeLimitInBytes: contains(eventHub, 'captureDescriptionSizeLimitInBytes') ? eventHub.captureDescriptionSizeLimitInBytes : 314572800
    captureDescriptionSkipEmptyArchives: contains(eventHub, 'captureDescriptionSkipEmptyArchives') ? eventHub.captureDescriptionSkipEmptyArchives : false
    consumerGroups: contains(eventHub, 'consumerGroups') ? eventHub.consumerGroups : []
    lock: contains(eventHub, 'lock') ? eventHub.lock : 'NotSpecified'
    messageRetentionInDays: contains(eventHub, 'messageRetentionInDays') ? eventHub.messageRetentionInDays : 1
    partitionCount: contains(eventHub, 'partitionCount') ? eventHub.partitionCount : 2
    roleAssignments: contains(eventHub, 'roleAssignments') ? eventHub.roleAssignments : []
    status: contains(eventHub, 'status') ? eventHub.status : 'Active'
  }
}]

module eventHubNamespace_diasterRecoveryConfig 'disasterRecoveryConfigs/deploy.bicep' = if (!empty(disasterRecoveryConfig)) {
  name: '${uniqueString(deployment().name, location)}-disasterRecoveryConfig'
  params: {
    namespaceName: eventHubNamespace.name
    name: disasterRecoveryConfig.name
    partnerNamespaceId: contains(disasterRecoveryConfig, 'partnerNamespaceId') ? disasterRecoveryConfig.partnerNamespaceId : ''
  }
}

module eventHubNamespace_authorizationRules 'authorizationRules/deploy.bicep' = [for (authorizationRule, index) in authorizationRules: {
  name: '${uniqueString(deployment().name, location)}-authorizationRules-${index}'
  params: {
    namespaceName: eventHubNamespace.name
    name: authorizationRule.name
    rights: contains(authorizationRule, 'rights') ? authorizationRule.rights : []
  }
}]

module eventHubNamespace_privateEndpoints '.bicep/nested_privateEndpoint.bicep' = [for (endpoint, index) in privateEndpoints: {
  name: '${uniqueString(deployment().name, location)}-PrivateEndpoints-${index}'
  params: {
    privateEndpointResourceId: eventHubNamespace.id
    privateEndpointVnetLocation: (empty(privateEndpoints) ? 'dummy' : reference(split(endpoint.subnetResourceId, '/subnets/')[0], '2020-06-01', 'Full').location)
    privateEndpointObj: endpoint
    tags: tags
  }
}]

module eventHubNamespace_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: eventHubNamespace.id
  }
}]

output namespace string = eventHubNamespace.name
output namespaceResourceId string = eventHubNamespace.id
output namespaceResourceGroup string = resourceGroup().name
output namespaceConnectionString string = listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
output sharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, '2017-04-01').primaryKey
