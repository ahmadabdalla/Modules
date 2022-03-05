<#
.SYNOPSIS
Recieves an Input Object of Key/Value pairs and sets them as environment variables on the host

.DESCRIPTION
Recieves an Input Object of Key/Value pairs and sets them as environment variables on the host

.PARAMETER KeyValuePair
Mandatory. An Hashtable that contains the Key and Value that are being outputted as environment variables (Key=Value)

.EXAMPLE
ss

#>
function Set-AzureDevOpsEnvVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $KeyValuePair,
        [Parameter(Mandatory = $false)]
        [bool] $ReturnVariable = $false
    )
    $Keys = $KeyValuePair.Keys.split(' ')
    foreach ($Key in $Keys) {
        Write-Verbose "$Key=$($KeyValuePair[$Key])" -Verbose
        Write-Output "##vso[task.setvariable variable=$Key]$($KeyValuePair[$Key])"
    }
}

