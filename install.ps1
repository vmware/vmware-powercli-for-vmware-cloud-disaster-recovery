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

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)][ValidateSet("LocalMachine", "CurrentUser")][string] $Install ,
    [Parameter(Mandatory = $false)][ValidateSet("LocalMachine", "CurrentUser")][string] $Uninstall,
    [Parameter(Mandatory = $false)][ValidateSet("LocalMachine", "CurrentUser")][string] $Update
)
#Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

# Stop script on error
$CmdletName = "VMware.VCDRService"


if ($IsWindows -or (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -eq 'Desktop'))) {
    $PSPaths = $ENV:PSModulePath -split ";"
}
else {
    $PSPaths = $ENV:PSModulePath -split ":"
}
if ($PSPaths.Count -ge 3) {
    $BASEDIR = $PSScriptRoot
    Write-Host "Starting local Install process"
    Write-Host "Root Directory is: $PSScriptRoot"
    Write-Host "#################################################################################"
    Write-Host
    $InstallerPath = join-path -Path $BASEDIR -ChildPath "publish"
    $vcdrSourcePath = join-path -Path $InstallerPath -ChildPath $CmdletName
    if ($Install) {
        Write-Host "Installing for $install"
        if ($install -eq "CurrentUser") {
            $PSPath = join-path -Path  $PSPaths[0]  -ChildPath $CmdletName
        }
        else {
            $PSPath = join-path -Path  $PSPaths[1]  -ChildPath $CmdletName
        }
        Write-Host "Checking if $PSPath already exist"
        if (Test-Path -Path $PSPath) {
            Write-Host "$PSPath exist."
            Write-Host "Installation failed"
            Write-Host "Please run ./install.ps1 -uninstall $install"
        }
        else {
            Write-Host "Installing CmdLets to $PSPath"
            copy-item -Path $vcdrSourcePath -Destination  $PSPath  -Recurse -force
            Write-Host 'Done.'
            Write-Host             
            Write-Host 'To start use: '
            Write-Host 'Connect-VCDRService   -token "<my VMC TOKEN>"'            
        }
    }
    elseif ($Uninstall) {
        if ($Uninstall -eq "CurrentUser") {
            $PSPath = join-path -Path  $PSPaths[0]  -ChildPath $CmdletName
        }
        else {
            $PSPath = join-path -Path  $PSPaths[1]  -ChildPath $CmdletName
        }
        Write-Host "Checking if $PSPath exist"
        if (Test-Path -Path $PSPath) {
            Write-Host "Removing CmdLets from $PSPath"
            Remove-Item $PSPath -Recurse -Force
            Write-Host "Done"
            Write-Host
        }
        else {
            Write-Host "No $CmdletName CmdLets founds"
        }
    }
    elseif ($Update) {
        & $BASEDIR\install.ps1 -Uninstall $Update
        & $BASEDIR\install.ps1 -Install $Update
        Write-Host "Update Done"
    }
    else {
        Write-Host "Usage ./install.ps1 [-Install LocalMachine|CurrentUser] | [-Uninstall LocalMachine|CurrentUser] | [-Update LocalMachine|CurrentUser]"
        Write-Host
    }
}