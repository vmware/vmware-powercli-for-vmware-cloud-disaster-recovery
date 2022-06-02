#
# Script module for module 'VMware.VCDRService'
#
Set-StrictMode -Version Latest

$binaryModuleFileName = 'VMware.VCDRService.psd1'

# Set up some helper variables to make it easier to work with the module
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

# Import the appropriate nested binary module based on the current PowerShell version
$binaryModuleRoot = $PSModuleRoot

if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')) {
   $binaryModuleRoot = Join-Path -Path $PSModuleRoot -ChildPath 'netcore'
}
else {
   $binaryModuleRoot = Join-Path -Path $PSModuleRoot -ChildPath 'net'
}

$binaryModulePath = Join-Path -Path $binaryModuleRoot -ChildPath $binaryModuleFileName
$binaryModule = Import-Module -Name $binaryModulePath -PassThru

# When the module is unloaded, remove the nested binary module that was loaded with it
$PSModule.OnRemove = {
   Remove-Module -ModuleInfo $binaryModule
}
