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
        if (Test-Path $Env:GITHUB_ENV -ErrorAction SilentlyContinue) {
            Write-Verbose "$Key=$($KeyValuePair[$Key])"
            Write-Output "$Key=$($KeyValuePair[$Key])" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
        }
        #[System.Environment]::SetEnvironmentVariable($Key, $KeyValuePair[$Key])
        $EnvironmentVariables += "$Key=$($KeyValuePair[$Key])`n"
    }
    # Output environment variable content
    if ($ReturnVariable) {
        return [string]$EnvironmentVariables
    }
}
