<#
.SYNOPSIS
Get a list of all resources (provider + service) in the given template content

.DESCRIPTION
Get a list of all resources (provider + service) in the given template content. Crawls through any children & nested deployment templates.

.PARAMETER TemplateFileContent
Mandatory. The template file content object to crawl data from

.EXAMPLE
Get-NestedResourceList -TemplateFileContent @{ resource = @{}; ... }

Returns a list of all resources in the given template object
#>
function Get-NestedResourceList {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $TemplateContent
    )

    $res = @()
    $currLevelResources = @()
    if ($TemplateContent.resources) {
        $currLevelResources += $TemplateContent.resources
    }
    foreach ($resource in $currLevelResources) {
        $res += $resource

        if ($resource.type -eq 'Microsoft.Resources/deployments') {
            $res += Get-NestedResourceList -TemplateContent $resource.properties.template
        } else {
            $res += Get-NestedResourceList -TemplateContent $resource
        }
    }
    return $res
}





function Find-TokenMismatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $InputObject,

        [Parameter(Mandatory)]
        [string[]] $Pattern
    )

    foreach ($Item in $InputObject) {
        if (!($Item | Select-String -Pattern $Pattern -Quiet)) {
            $MismatchDetected = $true
            break
        }
    }
    return [bool]$MismatchDetected
}

function Get-NotePropertiesNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $InputObject
    )

    $NotePropertiesNames = $InputObject | Get-Member -ErrorAction SilentlyContinue | Where-Object -Property MemberType -EQ 'NoteProperty' | Select-Object -ExpandProperty Name
    return [array]$NotePropertiesNames
}

function Get-TokenVisibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Pattern,

        [Parameter(Mandatory)]
        [string] $KeyProperty,

        [Parameter(Mandatory)]
        [string] $KeyPatternPropertyName
    )

    $ParameterFileObj = Get-Content -Path $Path | ConvertFrom-Json -Depth 15
    $L0Keys = Get-NotePropertiesNames -InputObject $ParameterFileObj.parameters

    foreach ($L0Key In $L0Keys) {
        if ($L0Key -like "*$KeyProperty*") {
            $L0KeyPatternProperty = $ParameterFileObj.parameters.$L0Key.value.$KeyPatternPropertyName
            if (Find-TokenMismatch -InputObject $L0KeyPatternProperty -Pattern $Pattern) { $MismatchDetected = $true }
        } else {
            $L1Keys = Get-NotePropertiesNames -InputObject $ParameterFileObj.parameters.$L0Key.value
            foreach ($L1Key in $L1Keys) {
                if ($L1Key -like "*$KeyProperty*") {
                    $L1KeyPatternProperty = $ParameterFileObj.parameters.$L0Key.value.$L1Key.$KeyPatternPropertyName
                    if (Find-TokenMismatch -InputObject $L1KeyPatternProperty -Pattern $Pattern) { $MismatchDetected = $true }
                } else {
                    $L2Keys = Get-NotePropertiesNames -InputObject $ParameterFileObj.parameters.$L0Key.value.$L1Key
                    foreach ($L2Key in $L2Keys) {
                        if ($L2Key -like "*$KeyProperty*") {
                            $L2KeyPatternProperty = $ParameterFileObj.parameters.$L0Key.value.$L1Key.$L2Key.$KeyPatternPropertyName
                            if (Find-TokenMismatch -InputObject $L2KeyPatternProperty -Pattern $Pattern) { $MismatchDetected = $true }
                        } else {
                            $L3Keys = Get-NotePropertiesNames -InputObject $ParameterFileObj.parameters.$L0Key.value.$L1Key.$L2Key
                            foreach ($L3Key in $L3Keys) {
                                if ($L3Key -like "*$KeyProperty*") {
                                    $L3KeyPatternProperty = $ParameterFileObj.parameters.$L0Key.value.$L1Key.$L2Key.$L3Key.$KeyPatternPropertyName
                                    if (Find-TokenMismatch -InputObject $L3KeyPatternProperty -Pattern $Pattern) { $MismatchDetected = $true }
                                } else {
                                    $L4Keys = Get-NotePropertiesNames -InputObject $ParameterFileObj.parameters.$L0Key.value.$L1Key.$L2Key.$L3Key
                                    foreach ($L4Key in $L4Keys) {
                                        if ($L4Key -like "*$KeyProperty*") {
                                            $L4KeyPatternProperty = $ParameterFileObj.parameters.$L0Key.value.$L1Key.$L2Key.$L3Key.$L4Key.$KeyPatternPropertyName
                                            if (Find-TokenMismatch -InputObject $L4KeyPatternProperty -Pattern $Pattern) { $MismatchDetected = $true }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return [bool]$MismatchDetected
}
