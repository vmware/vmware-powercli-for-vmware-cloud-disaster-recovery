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
    [Parameter(Mandatory = $true)][string] $token ,
    [Parameter(Mandatory = $true)] [string] $server
)
Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

$VCDR = Connect-VCDRServer  -server $server -token $token
Write-Output "Connected to $server"
$VCDR | Format-Table

$RecoverySDDC = Get-VCDRRecoverySDDC
if ($RecoverySDDC) {
    Write-Output "Recovery SDDCs:" -NoNewline
    $RecoverySDDC | Format-Table
}
else {
    Write-Output "No Recovery SDDCs configured"
}
$cloudFileSystems = Get-VCDRCloudFileSystem
if ($cloudFileSystems) {
    foreach ($cloudFileSystem in $cloudFileSystems) {
        Write-Output "Cloud FileSystem: $($cloudFileSystem.Name)" -NoNewline
        $cloudFileSystem | Format-Table
        Write-Output "Protected Sites:" -NoNewline
        $ProtectedSites = Get-VCDRProtectedSite -CloudFileSystem $cloudFileSystem
        $ProtectedSites | Format-Table

        $ProtectionGroups = Get-VCDRProtectionGroup  -CloudFileSystem $cloudFileSystem
        if ($ProtectionGroups) {
            Write-Output "Protection Groups:" -NoNewline
            $ProtectionGroups | Format-Table -RepeatHeader
            $Snapshots = Get-VCDRSnapshot   -ProtectionGroups $ProtectionGroups
            if ($Snapshots) {
                Write-Output "Snapshots:" -NoNewline
                $Snapshots | Format-Table -RepeatHeader
            }
            else {
                Write-Output "No Snapshots"
            }
        }
        else {
            Write-Output "No Protection Groups"
        }
        $Vms = Get-VCDRProtectedVm -CloudFileSystem $cloudFileSystem
        if ($Vms){
            Write-Output "Virtual Machines:" -NoNewline
            $Snapshots | Format-Table -RepeatHeader
        }
        else {
            Write-Output "No Virtual Machines on this Cloud File System"
        }

        Write-Output "`n********************`n"
    }
}

Disconnect-VCDRServer