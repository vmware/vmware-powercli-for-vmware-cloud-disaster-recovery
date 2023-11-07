#################################################################################
# Copyright (C) 2022, VMware Inc
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#################################################################################



 
<#
        .SYNOPSIS
            Simple VCDR PowerShell script
        .DESCRIPTION
            Connect to VCDR and show all content
        .PARAMETER Server
            Specifies the VCDR Server systems on which you want to run the cmdlet.
        .PARAMETER Token
           VMC API token

        .EXAMPLE
            .\VCDR-test.ps1  -token "<my VMC TOKEN>"
            Description
            -----------
            Run the test

        .NOTES
            FunctionName    : start-VCDRTest
            Created by      : VMware 
            Modified by     : VMware
            Date Modified   : 2022/08/1
            More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
        .LINK

    #>




    
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)][string] $Token ,
    [Parameter(Mandatory = $false)][string] $Server,
    [Parameter(Mandatory = $false)][Switch] $Connect,
    [Parameter(Mandatory = $false)][Switch] $Vim,
    [Parameter(Mandatory = $true)][string]$VIServer,
    [Parameter(Mandatory = $false)][string]$VIServer2,
    [PSCredential] $Credential ,
    [String]$username,
    [String]$Password
)
 
 
 
$ErrorActionPreference = 'Stop' 
if ($Password -and $username) {
    $secureString = ConvertTo-SecureString -AsPlainText -Force -String $Password
    $credential = [System.Management.Automation.PSCredential]::new($Username, $secureString)
} elseif (!$Credential) {
    $Credential = Get-Credential
}

if (! $Connect) {
    $Version = Get-Content -Path .\VERSION
    Write-Host "VMware VCDR PowerCLI version $Version"
    # Import-Module ".\publish\VMware.VCDRService\$Version\VMware.VCDRService.psd1"
    Connect-VIServer -Server $VIServer -Credential $Credential
    if ($VIServer2) {
        Connect-VIServer -Server $VIServer2 -Credential $Credential
    }
    if ($Server) {
        Connect-VCDRService -Token $Token -Server $Server
    } else {
        Connect-VCDRService -Token $Token
    }
}

$cloudFileSystems = Get-VCDRCloudFileSystem
if ($cloudFileSystems) {
    foreach ($cloudFileSystem in $cloudFileSystems) {
        Write-Host "Cloud FileSystem: $($cloudFileSystem.Name)" 
        $cloudFileSystem | Format-Table

        #[VMware.VCDRService.ProtectionGroup[]]
        $ProtectionGroups = Get-VCDRProtectionGroup -CloudFileSystem $cloudFileSystem
        if ($ProtectionGroups) {

            Write-Host 'Protection Groups:' -NoNewline
            $ProtectionGroups | Format-Table -RepeatHeader 
            foreach ($ProtectionGroup  in $ProtectionGroups) {
                $ProtectionGroup | Get-VmFromVCDR | Format-Table -RepeatHeader
                $Snapshots = Get-VCDRSnapshot -ProtectionGroups $ProtectionGroup

                $VMSnapshots = @{}
                foreach ( $snap in $Snapshots) {
                    $ProtVms = Get-VCDRProtectedVm -CloudFileSystem $cloudFileSystem -ProtectionGroupSnapshot $Snap
                    foreach ($vm in Get-VmFromVCDR -Vm $ProtVms) {
                        $uuid = ($vm | Get-View).config.InstanceUuid
                        if ($VMSnapshots.ContainsKey($uuid)) { 
                            $VMSnapshots[$uuid].snapshots += $snap 
                        } else { 
                            $VMSnapshots[$uuid] = @{
                                vm        = $Vm
                                snapshots = @($snap)  
                            }
                        }
                    }
                }  
            }

            if ($Snapshots) {
                Write-Host $('Protection Group:{0} Status:{1}' -f $ProtectionGroup.Name , $ProtectionGroup.Health)
                Write-Host 'Snapshots:' -NoNewline
                $Snapshots | Format-Table -RepeatHeader 
            } else {
                Write-Host 'No Snapshots'
            } 
        } else {
            Write-Host 'No Protection Groups'
        }
    }

    
    Write-Host "`n********************`n"
}else {
    Write-Host 'No VCDR CFS available'
}

    
Disconnect-VCDRService
Write-Host "Bye.`n"




 