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
    $InstallerPath = $(Get-ChildItem -Path $MyInvocation.MyCommand.Path).DirectoryName
    if($InstallerPath -is [system.array]){ $InstallerPath=$InstallerPath[0] }
    $vcdrSourcePath = join-path -Path $InstallerPath -ChildPath $CmdletName
    if ($Install) {
        Write-Output "Installing for $install"
        if ($install -eq "CurrentUser") {
            $PSPath = join-path -Path  $PSPaths[0]  -ChildPath $CmdletName
        }
        else {
            $PSPath = join-path -Path  $PSPaths[1]  -ChildPath $CmdletName
        }
        Write-Output "Checking if $PSPath already exist"
        if (Test-Path -Path $PSPath) {
            Write-Output "$PSPath exist."
            Write-Output "Installation failed`n"
            Write-Output "Please run ./install.ps1 -uninstall $install"
        }
        else {
            Write-Output "Installing CmdLets to $PSPath"
            copy-item -Path $vcdrSourcePath -Destination  $PSPath  -Recurse -force
            Write-Output 'Done.`n'
            Write-Output 'To start use: '
            Write-Output 'Connect-VCDRServer -server "vcdr-xxx-yyy-zzz-kkk.app.vcdr.vmware.com" -token "<my VMC TOKEN>"'
        }
    }
    elseif ($Uninstall) {
        if ($Uninstall -eq "CurrentUser") {
            $PSPath = join-path -Path  $PSPaths[0]  -ChildPath $CmdletName
        }
        else {
            $PSPath = join-path -Path  $PSPaths[1]  -ChildPath $CmdletName
        }
        Write-Output "Checking if $PSPath exist"
        if (Test-Path -Path $PSPath) {
            Write-Output "Removing CmdLets from $PSPath"
            Remove-Item $PSPath -Recurse -Force
            Write-Output "Done"
        }
        else {
            Write-Output "No $CmdletName CmdLets founds"
        }
    }   elseif ($Update) {
        & $InstallerPath\install.ps1 -Uninstall $Update
        & $InstallerPath\install.ps1 -Install $Update
        Write-Output "Update Done"
    }
    else {
        Write-Output "Usage ./install.ps1 [-Install LocalMachine|CurrentUser] | [-Uninstall LocalMachine|CurrentUser] | [-Update LocalMachine|CurrentUser]"
    }
}