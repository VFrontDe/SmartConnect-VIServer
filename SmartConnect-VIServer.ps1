Function SmartConnect-VIServer {
<#
.SYNOPSIS
    Connect to a vCenter server or ESXi host using saved credentials

.DESCRIPTION
    Uses and updates the VICredentialStore to avoid manually providing credentials

.EXAMPLE
    SmartConnect-VIServer vcsa.lab.local

.NOTES
    Author: Andreas Peetz
    Last Edit: 2019-10-24
    Version 1.0 - initial release
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)][boolean]$Force=$False,
        [Parameter(Mandatory=$False)][boolean]$NotDefault=$False,
        [Parameter(Mandatory=$False)][int]$Port,
        [Parameter(Mandatory=$False)][ValidateSet('http','https')][string]$Protocol="https",
        [Parameter(Mandatory=$True,Position=0)][string]$Server
    )

    Process {
        if ($Port -eq 0) {
            if ($Protocol -eq "http") { $Port = 80 } else { $Port = 443 }
        }
        if ($ci = Get-VICredentialStoreItem | ? { $_.Host -eq $Server }) {
            ("(Trying saved credentials of user " + $ci.User + " ...)")
            try {
                $vConn = Connect-VIServer -Server $Server -User $ci.User -Password $ci.Password -Force:$Force -NotDefault:$NotDefault -Port $Port -Protocol $Protocol
            }
            catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin] {
                     ("(Saved credentials are invalid. Prompting for updated credentials ...)")
                     $vConn = Connect-VIServer -Server $Server -Credential (Get-Credential -Message ("Update credentials (" + $Server + ")") -UserName $ci.User) -SaveCredentials -Force:$Force -NotDefault:$NotDefault -Port $Port -Protocol $Protocol
            }
        } else {
            ("(No saved credentials found, prompting ...)")
            $vConn = Connect-VIServer -Server $Server -Credential (Get-Credential -Message ("Enter credentials (" + $Server + ")")) -SaveCredentials -Force:$Force -NotDefault:$NotDefault -Port $Port -Protocol $Protocol
        }
        Return $vConn
    }

}