
<#
.SYNOPSIS
Test

.DESCRIPTION
Test. If git cannot find it, best effort based on environment variables is used.

.EXAMPLE
Get-CurrentBranch

#>

function Confirm-ModulesToPublishOnBranchType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject] $modulesToPublish
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        # Load helper functions
        . (Join-Path $PSScriptRoot 'Get-ModulesToPublish.ps1')
    }

    process {
        $CurrentBranch = Get-GitBranchName
        if ($CurrentBranch -ne 'main' -or $CurrentBranch -ne 'master') {
            Write-Verbose "Filtering modules to only publish [prerelease] version as the current branch [$CurrentBranch] is not [main/master]." -Verbose
            $modulesToPublish = $modulesToPublish | Where-Object -Property version -Like '*-prerelease'
            $modulesToPublish
        }
        return $ModifiedFiles
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
