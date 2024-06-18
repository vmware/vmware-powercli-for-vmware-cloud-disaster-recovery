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
    .\VCDR-test.ps1 -Token "<my VMC TOKEN>"
    Description
    -----------
    Run the test
.NOTES
    FunctionName    : start-VCDRTest
    Created by      : VMware 
    Modified by     : VMware
    Date Modified   : 2022/08/01
    More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
.LINK
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)][string] $Token,
    [Parameter(Mandatory = $false)][string] $Server,
    [Parameter(Mandatory = $false)][Switch] $Connect,
    [Parameter(Mandatory = $false)][Switch] $Vim,
    [Parameter(Mandatory = $false)][string] $Vcenter,
    [Parameter(Mandatory = $false)][string] $VcenterUser,
    [Parameter(Mandatory = $false)][string] $VcenterPassword
)

# Import necessary modules
Import-Module -Name VMware.PowerCLI
Import-Module -Name VMware.VCDRService

# Set strict mode and error handling preferences
Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

# Connect to vCenter and VCDR services if $Connect switch is not used
if (-not $Connect) {
    # Connect to vCenter
    Connect-VIServer -Server $Vcenter -User $VcenterUser -Password $VcenterPassword
    
    # Connect to VCDR service
    if ($Server) {
        Connect-VCDRService -Token $Token -Server $Server
    } else {
        Connect-VCDRService -Token $Token
    }
}

# Get and display VCDR instances
Get-VCDRInstance

# Get and display Recovery SDDCs
$RecoverySDDC = Get-VCDRRecoverySDDC
if ($RecoverySDDC) {
    Write-Host 'Recovery SDDCs:'
    $RecoverySDDC | Format-Table
} else {
    Write-Host 'No Recovery SDDCs configured'
}

# Get and display Cloud File Systems
$cloudFileSystems = Get-VCDRCloudFileSystem
if ($cloudFileSystems) {
    foreach ($cloudFileSystem in $cloudFileSystems) {
        Write-Host "Cloud FileSystem: $($cloudFileSystem.Name)"
        $cloudFileSystem | Format-Table
        
        # Get and display Protection Groups
        $protectionGroups = Get-VCDRProtectionGroup -CloudFileSystem $cloudFileSystem
        if ($protectionGroups) {
            Write-Host 'Protection Groups:'
            $protectionGroups | Format-Table -RepeatHeader
            $protectionGroups | Get-VmFromVCDR | Format-Table -RepeatHeader
            
            # Initialize a hash table to store VM snapshots
            $VMSnapshots = @{}
            
            # Get and display snapshots for each Protection Group
            foreach ($protectionGroup in $protectionGroups) {
                $protectionGroup | Get-VmFromVCDR | Format-Table -RepeatHeader
                $snapshots = Get-VCDRSnapshot -ProtectionGroups $protectionGroup
                

                # Display snapshots
                if ($snapshots) {
                    Write-Host $('Protection Group:{0} Status:{1}' -f $protectionGroup.Name, $protectionGroup.Health)
                    Write-Host 'Snapshots:'
                    $snapshots | Format-Table -RepeatHeader

                    # Process each snapshot
                    foreach ($snap in $snapshots) {
                        $protVms = Get-VCDRProtectedVm -CloudFileSystem $cloudFileSystem -ProtectionGroupSnapshot $snap
                        foreach ($vm in Get-VmFromVCDR -Vm $protVms) {
                            $uuid = ($vm | Get-View).config.InstanceUuid
                            if ($VMSnapshots.ContainsKey($uuid)) {
                                $VMSnapshots[$uuid].snapshots += $snap
                            } else {
                                $VMSnapshots[$uuid] = @{
                                    vm = $Vm.Name                                    
                                    snapshots = @($snap)
                                }
                            }
                        }
                    } 

                } else {
                    Write-Host 'No Snapshots'
                }
            }
        } else {
            Write-Host 'No Protection Groups'
        }
        Write-Host  'Snapshots by VM'
        Write-Host ($VMSnapshots|ConvertTo-Json -Depth 99 -AsArray)

        # Get and display Protected Sites
        Write-Host 'Protected Sites:'
        $ProtectedSites = Get-VCDRProtectedSite -CloudFileSystem $cloudFileSystem -Vcenter $global:DefaultVIServers[0] -ProtectionGroup $protectionGroups
        $ProtectedSites | Format-Table
        
        # Get and display Protected VMs
        $Vms = Get-VCDRProtectedVm -CloudFileSystem $cloudFileSystem
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VimVms = $Vms | Get-VmFromVCDR -ErrorAction Continue
        
        if ($VimVms) {
            Write-Host 'Virtual Machines:'
            $VimVms | Format-Table -RepeatHeader
        } else {
            Write-Host 'No Virtual Machines on this Cloud File System'
        }
        
        Write-Host "`n********************`n"
    }
}

# Disconnect from VCDR service
Disconnect-VCDRService
Write-Host "Bye.`n"
