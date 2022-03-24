<#
.SYNOPSIS
Reads a YAML file that contains a list (List / hashtable) of key-value pairs within it and outputs a file with the key-value pair in a (key1=value1) format. Suitable for environment variables

.DESCRIPTION
Accepts input for a YAML file that contains a List, which has key-value pairs (also known as scalars) like key1: 'value1' in each line, and outputs a file with the key-value pair in a (key1=value1) format.
See File structure below:

ListName:
    key1: value1
    key2: value2

Output file will contain:
key1=value1
key2=value2

.PARAMETER InputFilePath
Mandatory. The path to the YAML file that contains the key-value pairs List.

.PARAMETER ListName
Mandatory. The name of the List in the file that contains the key-value pair.

.PARAMETER OutputFilePath
Mandatory. The path to the file to converted key-value pairs to (format will be key1=value1)

.EXAMPLE
Convert-YamlList -InputFilePath C:\MyFile.yaml -ListName variables -OutputFilePath C:\MyFile.txt -verbose

Important: Requires the PowerShell module 'powershell-yaml' to be installed.
#>

function Convert-YamlList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $InputFilePath,

        [Parameter(Mandatory)]
        [string] $ListName,

        [Parameter(Mandatory)]
        [string] $OutputFilePath
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        # Check if the 'powershell-yaml' module is installed
        if (-not (Get-InstalledModule -Name 'powershell-yaml')) {
            throw "PowerShell module 'powershell-yaml' is required for for serializing and deserializing YAML.`nInstall using:`nInstall-Module 'powershell-yaml' -Repository PSGallery"
        } elseif (-not (Get-Module 'powershell-yaml')) {
            Import-Module 'powershell-yaml'
        }

        try {
            # Check if input file path is valid
            if (-not ($File = Get-Content -Path $InputFilePath -ErrorAction SilentlyContinue)) {
                throw "Invalid Input File Path: $InputFilePath"
            }
            # Check if output file path is valid
            if (-not (Test-Path $OutputFilePath)) {
                throw "Invalid Output File Path: $OutputFilePath"
            }
        } catch {
            throw $PSitem.Exception.Message
        }
    }

    process {

        # Process List (Hashtable)
        try {
            $KeyValuePair = $File | ConvertFrom-Yaml | Select-Object -ExpandProperty $ListName
            Write-Verbose "Found $($KeyValuePair.Count) Key-Value pairs in List: $ListName" -Verbose
            if (-not $KeyValuePair) {
                throw "No key-value pairs found in List: $ListName"
            }
            # Process key value pairs
            foreach ($Key in $KeyValuePair.Keys.split(' ')) {
                Write-Output "$Key=$($KeyValuePair[$Key])" | Out-File -FilePath $OutputFilePath -Encoding utf-8 -Append
            }
        } catch {
            throw $PSitem.Exception.Message
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
