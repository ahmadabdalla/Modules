@description('Required. Name of the Azure Recovery Service Vault')
@minLength(1)
param name string

@description('Optional. The storage configuration for the Azure Recovery Service Vault')
param backupStorageConfig object = {}

@description('Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered')
param cuaId string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. List of all backup policies.')
param backupPolicies array = []

@description('Optional. List of all protection containers.')
@minLength(0)
param protectionContainers array = []

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource identifier of the Diagnostic Storage Account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource identifier of Log Analytics.')
param workspaceId string = ''

@description('Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param eventHubAuthorizationRuleId string = ''

@description('Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param eventHubName string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'')
param roleAssignments array = []

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. Tags of the Recovery Service Vault resource.')
param tags object = {}

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'AzureBackupReport'
  'CoreAzureBackup'
  'AddonAzureBackupJobs'
  'AddonAzureBackupAlerts'
  'AddonAzureBackupPolicy'
  'AddonAzureBackupStorage'
  'AddonAzureBackupProtectedInstance'
  'AzureSiteRecoveryJobs'
  'AzureSiteRecoveryEvents'
  'AzureSiteRecoveryReplicatedItems'
  'AzureSiteRecoveryReplicationStats'
  'AzureSiteRecoveryRecoveryPoints'
  'AzureSiteRecoveryReplicationDataUploadRate'
  'AzureSiteRecoveryProtectedDiskDataChurn'
])
param logsToEnable array = [
  'AzureBackupReport'
  'CoreAzureBackup'
  'AddonAzureBackupJobs'
  'AddonAzureBackupAlerts'
  'AddonAzureBackupPolicy'
  'AddonAzureBackupStorage'
  'AddonAzureBackupProtectedInstance'
  'AzureSiteRecoveryJobs'
  'AzureSiteRecoveryEvents'
  'AzureSiteRecoveryReplicatedItems'
  'AzureSiteRecoveryReplicationStats'
  'AzureSiteRecoveryRecoveryPoints'
  'AzureSiteRecoveryReplicationDataUploadRate'
  'AzureSiteRecoveryProtectedDiskDataChurn'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'Health'
])
param metricsToEnable array = [
  'Health'
]

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

resource rsv 'Microsoft.RecoveryServices/vaults@2021-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

module rsv_backupStorageConfiguration 'backupStorageConfig/deploy.bicep' = {
  name: '${uniqueString(deployment().name, location)}-BackupStorageConfig'
  params: {
    recoveryVaultName: rsv.name
    storageModelType: backupStorageConfig.storageModelType
    crossRegionRestoreFlag: backupStorageConfig.crossRegionRestoreFlag
  }
}

module rsv_protectionContainers 'protectionContainers/deploy.bicep' = [for (protectionContainer, index) in protectionContainers: {
  name: '${uniqueString(deployment().name, location)}-ProtectionContainers-${index}'
  params: {
    recoveryVaultName: rsv.name
    name: protectionContainer.name
    sourceResourceId: protectionContainer.sourceResourceId
    friendlyName: protectionContainer.friendlyName
    backupManagementType: protectionContainer.backupManagementType
    containerType: protectionContainer.containerType
  }
}]

module rsv_backupPolicies 'backupPolicies/deploy.bicep' = [for (backupPolicy, index) in backupPolicies: {
  name: '${uniqueString(deployment().name, location)}-BackupPolicy-${index}'
  params: {
    recoveryVaultName: rsv.name
    name: backupPolicy.name
    backupPolicyProperties: backupPolicy.properties
  }
}]

resource rsv_lock 'Microsoft.Authorization/locks@2016-09-01' = if (lock != 'NotSpecified') {
  name: '${rsv.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: rsv
}

resource rsv_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(workspaceId)) || (!empty(eventHubAuthorizationRuleId)) || (!empty(eventHubName))) {
  name: '${rsv.name}-diagnosticSettings'
  properties: {
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    workspaceId: empty(workspaceId) ? null : workspaceId
    eventHubAuthorizationRuleId: empty(eventHubAuthorizationRuleId) ? null : eventHubAuthorizationRuleId
    eventHubName: empty(eventHubName) ? null : eventHubName
    metrics: (empty(diagnosticStorageAccountId) && empty(workspaceId) && empty(eventHubAuthorizationRuleId) && empty(eventHubName)) ? null : diagnosticsMetrics
    logs: (empty(diagnosticStorageAccountId) && empty(workspaceId) && empty(eventHubAuthorizationRuleId) && empty(eventHubName)) ? null : diagnosticsLogs
  }
  scope: rsv
}

module rsv_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: rsv.id
  }
}]

@description('The resource ID of the Recovery Services Vault')
output recoveryServicesVaultResourceId string = rsv.id

@description('The name of the Resource Group the Recovery Services Vault was created in')
output recoveryServicesVaultResourceGroup string = resourceGroup().name

@description('The Name of the Recovery Services Vault')
output recoveryServicesVaultName string = rsv.name
