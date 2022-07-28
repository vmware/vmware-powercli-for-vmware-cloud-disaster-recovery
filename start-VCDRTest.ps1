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
            .\VCDR-test.ps1 -server "vcdr-xxx-yyy-zzz-kkk.app.vcdr.vmware.com" -token "<my VMC TOKEN>"
            Description
            -----------
            Run the test

        .NOTES
            FunctionName    : start-VCDRTest
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/04/15 12:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)][string] $token 
)
Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

Connect-VCDRService -Token   $token
Get-VCDRInstance

$RecoverySDDC = Get-VCDRRecoverySDDC
if ($RecoverySDDC) {
    Write-Host "Recovery SDDCs:" -NoNewline
    $RecoverySDDC | Format-Table
} else {
    Write-Host "No Recovery SDDCs configured"
}
$cloudFileSystems = Get-VCDRCloudFileSystem
if ($cloudFileSystems) {
    foreach ($cloudFileSystem in $cloudFileSystems) {
        Write-Host "Cloud FileSystem: $($cloudFileSystem.Name)" 
        $cloudFileSystem | Format-Table
        Write-Host "Protected Sites:" -NoNewline
        $ProtectedSites = Get-VCDRProtectedSite -CloudFileSystem $cloudFileSystem
        $ProtectedSites | Format-Table

        $ProtectionGroups = Get-VCDRProtectionGroup  -CloudFileSystem $cloudFileSystem
        if ($ProtectionGroups) {
            Write-Host "Protection Groups:" -NoNewline
            $ProtectionGroups | Format-Table -RepeatHeader
            $Snapshots = Get-VCDRSnapshot   -ProtectionGroups $ProtectionGroups
            if ($Snapshots) {
                Write-Host "Snapshots:" -NoNewline
                $Snapshots | Format-Table -RepeatHeader
            }
            else {
                Write-Host "No Snapshots"
            }
        }
        else {
            Write-Host "No Protection Groups"
        }
        $Vms = Get-VCDRProtectedVm -CloudFileSystem $cloudFileSystem
        if ($Vms){
            Write-Host "Virtual Machines:" -NoNewline
            $Snapshots | Format-Table -RepeatHeader
        }
        else {
            Write-Host "No Virtual Machines on this Cloud File System"
        }

        Write-Host "`n********************`n"
    }
}
Disconnect-VCDRService