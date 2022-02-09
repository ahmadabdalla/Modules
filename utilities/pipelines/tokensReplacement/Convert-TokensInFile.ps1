<#
.SYNOPSIS
This Function Aggregates all the different token types (Default, Local and Remote) and then passes them to the Convert Tokens Script to replace tokens in a parameter file

.DESCRIPTION
This Function Aggregates all the different token types (Default, Local and Remote) and then passes them to the Convert Tokens Script to replace tokens in a parameter file

.PARAMETER FilePath
Mandatory. The Path to the file that contains tokens to be replaced.

.PARAMETER Tokens
Mandatory. An object containing the parameter file tokens to set

.PARAMETER TokensKeyVaultName
Optional. A string for the Key Vault Name that contains the remote tokens

.PARAMETER TokensKeyVaultSubscriptionId
Optional. A string for the subscription Id where the Key Vault exists

.PARAMETER TokensKeyVaultSecretContentType
Optional. An identifier used to filter for the Token (Secret) in Key Vault using the ContentType Property (i.e. myTokenContentType)

.PARAMETER TokenPrefix
Mandatory. The prefix used to identify a token in the parameter file (i.e. <<)

.PARAMETER TokenSuffix
Mandatory. The suffix used to identify a token in the parameter file (i.e. >>)

.PARAMETER SwapValueWithName
Optional. A boolean that enables the search for the original value and replaces it with a token. Used to revert configuration. Default is false

.PARAMETER OutputDirectory
Optional. A string for a custom output directory of the modified parameter file

.NOTES
- Make sure you provide the right information in the objects that contain tokens. This is in the form of
 @(
        @{ Name = 'deploymentSpId'; Value = '12345678-1234-1234-1234-123456789123' }
        @{ Name = 'tenantId'; Value = '12345678-1234-1234-1234-123456789123' }

- Ensure you have the ability to perform the deployment operations using your account
- If providing TokenKeyVaultName parameter, ensure you have read access to secrets in the key vault to be able to retrieve the tokens.
#>

function Convert-TokensInFile {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [string] $FilePath,

        [parameter(Mandatory = $false, ParameterSetName = 'RemoteTokens')]
        [string]$TokensKeyVaultName,

        [parameter(Mandatory = $false, ParameterSetName = 'RemoteTokens')]
        [string]$TokensKeyVaultSubscriptionId,

        [parameter(Mandatory = $false, ParameterSetName = 'RemoteTokens')]
        [string]$TokensKeyVaultSecretContentType,

        [parameter(Mandatory = $true)]
        [hashtable] $Tokens,

        [parameter(Mandatory = $true)]
        [string] $TokenPrefix,

        [parameter(Mandatory = $true)]
        [string] $TokenSuffix,

        [parameter(Mandatory = $false)]
        [bool] $SwapValueWithName = $false,

        [parameter(Mandatory = $false)]
        [string] $OutputDirectory
    )

    begin {
        # Load used funtions
        . (Join-Path $PSScriptRoot './helper/Convert-TokenInFile.ps1')
        . (Join-Path $PSScriptRoot './helper/Get-TokenFromKeyVault.ps1')
    }

    process {
        ## Get Remote Custom Parameter File Tokens (Should Not Contain Sensitive Information if being passed to regular strings)
        #if ($TokensKeyVaultName -and $TokensKeyVaultSubscriptionId) {
        #    ## Prepare Input for Remote Tokens
        #    $RemoteTokensInput = @{
        #        KeyVaultName      = $TokensKeyVaultName
        #        SubscriptionId    = $TokensKeyVaultSubscriptionId
        #        SecretContentType = $TokensKeyVaultSecretContentType
        #    }
        #    $RemoteCustomParameterFileTokens = Get-TokenFromKeyVault @RemoteTokensInput -ErrorAction SilentlyContinue
        #    ## Add Tokens to All Custom Parameter File Tokens
        #    if (!$RemoteCustomParameterFileTokens) {
        #        Write-Verbose 'No Remote Custom Parameter File Tokens Detected'
        #    } else {
        #        Write-Verbose "Remote Custom Tokens Count: ($($RemoteCustomParameterFileTokens.Count)) Tokens (From Key Vault)"
        #        $AllCustomParameterFileTokens += $RemoteCustomParameterFileTokens
        #    }
        #}
        # Combine All Input Token Types, Remove Duplicates and Only Select entries with on empty values
        $FilteredTokens = ($Tokens | Sort-Object -Unique).Clone()
        @($FilteredTokens.Keys) | ForEach-Object {
            if ([String]::IsNullOrEmpty($FilteredTokens[$_])) {
                $FilteredTokens.Remove($_)
            }
        }
        Write-Verbose ('Using [{0}] tokens' -f $FilteredTokens.Keys.Count)

        # Apply Prefix and Suffix to Tokens and Prepare Object for Conversion
        Write-Verbose ("Applying Token Prefix '$TokenPrefix' and Token Suffix '$TokenSuffix'")
        foreach ($Token in @($FilteredTokens.Keys)) {
            $newKey = -join ($TokenPrefix, $Token, $TokenSuffix)
            $FilteredTokens[$newKey] = $FilteredTokens[$Token] # Add formatted entry
            $FilteredTokens.Remove($Token) # Replace original
        }
        # Convert Tokens in Parameter Files
        try {
            # Prepare Input to Token Converter Function
            $ConvertTokenListFunctionInput = @{
                FilePath             = $FilePath
                TokenNameValueObject = $FilteredTokens
                SwapValueWithName    = $SwapValueWithName
            }
            if ($OutputDirectory) {
                $ConvertTokenListFunctionInput += @{OutputDirectory = $OutputDirectory }
            }
            # Convert Tokens in the File
            Convert-TokenInFile @ConvertTokenListFunctionInput
            $ConversionStatus = $true
        } catch {
            $ConversionStatus = $false
            Write-Verbose $_.Exception.Message -Verbose
        }
    }
    end {
        Write-Verbose "Token Replacement Status: $ConversionStatus"
        return [bool] $ConversionStatus
    }
}
