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
        Build the CmdLets
    .DESCRIPTION
        Build the CmdLets
    .PARAMETER Version
        Define the CmdLets version. Default is the content of VERSION file
    .PARAMETER NuGetApiKey
        Key to publish to PowerShell Gallery
    .PARAMETER GitHubApiKey
        Key to publish to Github
    .PARAMETER Publish
        Publish to PowerShell Gallery. If not specified will use the -whatif option
    .PARAMETER OpenApiFile
        VCDR YAML file [Default: vcdr.yaml]
    

    .EXAMPLE
         .\build.ps1 -NuGetApiKey $apiKey -Version 2.0.0.1

    .NOTES
        FunctionName    : Connect-VCDRService
        Created by      : VMware
        Modified by     : VMware
        Date Modified   : 2022/08/01 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#>


[CmdletBinding()]
Param(
  [Parameter(Mandatory = $false)] [string] $Version ,
  [Parameter(Mandatory = $false)] [string] $NuGetApiKey,
  [Parameter(Mandatory = $false)] [string] $GitHubApiKey,
  [Parameter(Mandatory = $false)] [string] $OpenApiFile = 'vcdr.yaml',
  [Parameter(Mandatory = $false)] [Switch] $Publish,
  [Parameter(Mandatory = $false)] [String] $Prerelease
  
    
)
if ($NuGetApiKey)
{
  $Module = Get-Module -Name PowerShellGet
  if ($Module -and $Module.Version.Major -ge 2)
  {
    Write-Host 'PowerShellGet module installed.'
  }
  else
  { 
    throw "PowerShellGet module Version 2 or greater not installed. Please use 'Install-Module -Name PowerShellGet -force' and Retry"
  }
}

if ($GitHubApiKey)
{
  if (Get-Module -ListAvailable -Name PowerShellForGitHub )
  {
    Write-Host 'PowershellforGitHub module installed.'
  }
  else
  {
    throw "PowershellforGitHub module not installed. Please use 'Install-Module -Name PowerShellForGitHub' and Retry"
  }
}
#Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'
Write-Host 'Starting Build process'
Write-Host "Root Directory is: $PSScriptRoot"
Write-Host '#################################################################################'
Write-Host

$NSWAG_FRAMEWORK = 'NetCore31'
$CONFIGURATION = 'Release'
$FRAMEWORK = 'netcoreapp3.1'
$LEGACYFRAMEWORK = '4.7'
$PLATFORM = 'AnyCPU'
$BASEDIR = $PSScriptRoot

if ([string]::IsNullOrEmpty($Version))
{ 
  $Version = Get-Content -Path $BASEDIR\VERSION  
}
$VCDRSERVICE_DIRNAME = 'VMware.VCDRService'
$PUBLISH_FOLDER = "$BASEDIR\publish"
$VCDRSERVICELEGACY_DIRNAME = 'VMware.VCDRService_legacy'
$VCDRSERVICE_SRC = "$BASEDIR\c#.netcode\$VCDRSERVICE_DIRNAME"
$VCDRSERVICE_LEGACY_SRC = "$BASEDIR\c#.netcode\$VCDRSERVICELEGACY_DIRNAME"
$VCDRSERVICE_BASEDIR = "$PUBLISH_FOLDER\VMware.VCDRService"
$VCDRSERVICE_PWSH_SOURCE = "$BASEDIR\src"
$VCDRSERVICE = "$VCDRSERVICE_BASEDIR\$VERSION"
$VCDR_SWAG_DIR = "$BASEDIR\NSwag"
 
 
if ( -not (Test-Path $PUBLISH_FOLDER))
{
  #PowerShell Create directory if not exists
  New-Item $PUBLISH_FOLDER -ItemType Directory
}
else
{
  Remove-Item -Path $PUBLISH_FOLDER\*.zip
}

# Create the C# client
#NSWAG https://github.com/RicoSuter/NSwag has to be installed
#region NSWAG
Set-Location -Path $VCDR_SWAG_DIR
& nswag run .\CloudServicePlatform.nswag /runtime:$NSWAG_FRAMEWORK
& nswag run .\VcdrBackendPlatform.nswag /runtime:$NSWAG_FRAMEWORK
& nswag run .\vcdr.nswag /input:$OpenApiFile /runtime:$NSWAG_FRAMEWORK

 
#endregion NSWAG
# start NET BUILD
#region build
Set-Location -Path $VCDRSERVICE_SRC
& dotnet build

& msbuild -t:Rebuild -p:Configuration=$CONFIGURATION -p:Platform=$PLATFORM
Copy-Item -Path "$VCDRSERVICE_SRC\*.cs" -Destination $VCDRSERVICE_LEGACY_SRC -Verbose
Set-Location -Path $VCDRSERVICE_LEGACY_SRC
& msbuild VMware.VCDRService_legacy.csproj /p:Configuration=$CONFIGURATION /p:Platform=$PLATFORM /p:TargetFrameworkVersion=$LEGACYFRAMEWORK -t:Rebuild
Set-Location $BASEDIR
#endregion build

#Create Directories and copy files
#region CopyFiles
if (Test-Path -Path $VCDRSERVICE_BASEDIR)
{
  Remove-Item -Path $VCDRSERVICE_BASEDIR -Recurse -Force
}
New-Item -Path $VCDRSERVICE -ItemType Directory
New-Item -Path "$VCDRSERVICE\netcore" -ItemType Directory
New-Item -Path "$VCDRSERVICE\net" -ItemType Directory
Copy-Item -Path "$VCDRSERVICE_SRC\bin\$CONFIGURATION\$FRAMEWORK\*.dll" -Destination "$VCDRSERVICE\netcore"
Copy-Item -Path "$VCDRSERVICE_LEGACY_SRC\bin\$CONFIGURATION\*.dll" -Destination "$VCDRSERVICE\net"
Copy-Item -Path "$VCDRSERVICE_PWSH_SOURCE\VMware.VCDRService.psm1" -Destination "$VCDRSERVICE\net"
Copy-Item -Path "$VCDRSERVICE_PWSH_SOURCE\VMware.VCDRService.psm1" -Destination "$VCDRSERVICE\netcore"
Copy-Item -Path "$VCDRSERVICE_PWSH_SOURCE\Types.ps1xml" -Destination "$VCDRSERVICE"
Copy-Item -Path "$BASEDIR\LICENSE" -Destination "$VCDRSERVICE"
Copy-Item -Path "$BASEDIR\open_source_licenses.txt" -Destination "$VCDRSERVICE"
#endregion CopyFiles

#region CommonDescriptor
$TemplateHeaderPSD1 = @"
#
# Module manifest for module 'VMware.VCDRService' Core & Desktop
#
# Generated by: build.ps1
#
# Generated on: $(Get-Date)
#
@{

"@
#remaining descriptor contents
if ($Prerelease)
{ 
  $IsBeta = "# Prerelease string of this module `n      Prerelease   = '$Prerelease'" 
}
else
{   
  $IsBeta = "# Prerelease string of this module `n      #Prerelease   = 'Alpha'" 
}
$TemplatePSD1 = @"

  # Script module or binary module file associated with this manifest.
  RootModule           = 'VMware.VCDRService.psm1'

  # ID used to uniquely identify this module
  GUID                 = '151f6501-a080-4b44-851f-3626c97ea1a3'

  # Author of this module
  Author               = 'VMware'

  # Company or vendor of this module
  CompanyName          = 'VMware, Inc.'

  # Copyright statement for this module
  Copyright            = '$(Get-Date -UFormat '%Y')(c) VMware Inc. All rights reserved.'

  # Description of the functionality provided by this module
  Description          = 'PowerCLI VMware Cloud Disaster Recovery module'
  
  # Processor architecture (None, X86, Amd64) required by this module
  # ProcessorArchitecture = ''

  # Modules that must be imported into the global environment prior to importing this module
  RequiredModules = @(
    @{"ModuleName"="VMware.VimAutomation.Sdk";"ModuleVersion"="12.7.0.20067606"}
    @{"ModuleName"="VMware.VimAutomation.Common";"ModuleVersion"="12.7.0.20067789"}
    @{"ModuleName"="VMware.Vim";"ModuleVersion"="7.0.3.19601056"}
    @{"ModuleName"="VMware.VimAutomation.Core";"ModuleVersion"="12.7.0.20091293"}
  )

  # Script files (.ps1) that are run in the caller's environment prior to importing this module.
  # ScriptsToProcess = @()

  # Type files (.ps1xml) to be loaded when importing this module
  #TypesToProcess = @("Types.ps1xml")

  # Format files (.ps1xml) to be loaded when importing this module
  # FormatsToProcess = @()

  # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
  # NestedModules = @()

  # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
  # FunctionsToExport    = @()

  # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
  CmdletsToExport      = @("Connect-VCDRService","Disconnect-VCDRService","Get-VCDRInstance","Get-DefaultVCDRInstance","Set-DefaultVCDRInstance", "Get-VCDRCloudFileSystem", "Get-VCDRProtectedSite", "Get-VCDRProtectionGroup", "Get-VCDRSnapshot", "Get-VCDRProtectedVm", "get-VCDRRecoverySddc","Get-VmFromVCDR","Remove-HFSFilter","Get-HFSFilter")

  # Variables to export from this module
  VariablesToExport    = '*'

  # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
  AliasesToExport      = @("Connect-VCDRServer",  "Disconnect-VCDRServer")

  # DSC resources to export from this module
  # DscResourcesToExport = @()

  # List of all modules packaged with this module
  # ModuleList = @()

  # List of all files packaged with this module
  # FileList = @()

  # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
  PrivateData          = @{

    PSData = @{

      # Tags applied to this module. These help with module discovery in online galleries.
      # Tags = @()

      # A URL to the license for this module.
      LicenseUri = 'https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery/blob/main/LICENSE'

      # A URL to the main website for this project.
      ProjectUri = 'https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery'

      # A URL to an icon representing this module.
      IconUri      = 'https://raw.githubusercontent.com/vmware/PowerCLI-Example-Scripts/1710f7ccbdd9fe9a3ab3f000e920fa6e8e042c63/resources/powercli-psgallery-icon.svg'

      # ReleaseNotes of this module
      ReleaseNotes = 'VMware Cloud Disaster Recovery PowerShell CmdLets'

      $IsBeta

      # Flag to indicate whether the module requires explicit user acceptance for install/update/save
      # RequireLicenseAcceptance = $false

      # External dependent modules of this module
      # ExternalModuleDependencies = @()

    } # End of PSData hashtable

  } # End of PrivateData hashtable

  # HelpInfo URI of this module
  # HelpInfoURI = ''

  # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
  # DefaultCommandPrefix = ''

}
"@
#endregion CommonDescriptor

#region VMware.VCDRService.psm1
# VMware.VCDRService.psm1 Net selector
@'
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
'@| Set-Content "$VCDRSERVICE\VMware.VCDRService.psm1"
#endregion VMware.VCDRService.psm1

#region CoreDescriptor
#descriptor for Standard Core
$VariableTemplateCorePSD1 = @"
  # Version number of this module.
  ModuleVersion        = '$Version'

  # Supported PSEditions
  CompatiblePSEditions = 'Core'

  # Assemblies that must be loaded prior to importing this module
  RequiredAssemblies   = @("VMware.VCDRService.dll")
  
  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '6.0.4'
"@
$TemplateHeaderPSD1 + $VariableTemplateCorePSD1 + $TemplatePSD1 | Set-Content -Path "$VCDRSERVICE\netcore\VMware.VCDRService.psd1"
#endregion CoreDescriptor

#region NetDescriptor
#descriptor for Standard .Net
$VariableTemplateNetPSD1 = @"
  # Version number of this module.
  ModuleVersion        = '$Version'

  # Supported PSEditions
  CompatiblePSEditions = 'Desktop'

  # Assemblies that must be loaded prior to importing this module
  RequiredAssemblies   = @("VMware.VCDRService.dll")
 
  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '5.1'

  # Minimum version of the Windows PowerShell host required by this module
  PowerShellHostVersion = ''

  # Minimum version of the .NET Framework required by this module
  DotNetFrameworkVersion = '4.5'

  # Minimum version of the common language runtime (CLR) required by this module
  CLRVersion = '4.0'
"@

$TemplateHeaderPSD1 + $VariableTemplateNetPSD1 + $TemplatePSD1 | Set-Content -Path "$VCDRSERVICE\net\VMware.VCDRService.psd1"
#endregion NetDescriptor

#region NetSelectorDescriptor
#descriptor for .Net selector
$VariableTemplateCoreNetPSD1 = @"
  # Version number of this module.
  ModuleVersion        = '$Version'

  # Supported PSEditions
  CompatiblePSEditions = 'Desktop', 'Core'

  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '5.1'
  # Type files (.ps1xml) to be loaded when importing this module
  TypesToProcess = @("Types.ps1xml")
   
"@

$TemplateHeaderPSD1 + $VariableTemplateCoreNetPSD1 + $TemplatePSD1 | Set-Content "$VCDRSERVICE\VMware.VCDRService.psd1"
#endregion NetSelectorDescriptor
Set-Location $BASEDIR
#region Archive 
$DestZip = "$PUBLISH_FOLDER\VMware.VCDRService-{0}.zip" -f $Version.replace( '.', '-') 
Compress-Archive -Path @("$PUBLISH_FOLDER\VMware.VCDRService", '.\install.ps1', 'LICENSE', 'NOTICE', 'open_source_licenses.txt') -DestinationPath $DestZip
#endregion Archive

#region NuGet
if ( $NuGetApiKey )
{
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Publish-Module -Path $VCDRSERVICE -NuGetApiKey $NuGetApiKey -WhatIf -Verbose
  if ($Publish)
  { 
    Write-Output "Publish flag detected - Start publishing on PSGallery `n"
    Publish-Module -Path $VCDRSERVICE -NuGetApiKey $NuGetApiKey -Verbose 
  }
  else
  {
    Write-Output "To Publish run:`n  Publish-Module -Path $VCDRSERVICE  -NuGetApiKey $NuGetApiKey -Verbose "
  }
}
#endregion NuGet

#region GitHub
if ($GitHubApiKey)
{
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Write-Output "Creating a new version on GitHub`n"
  $RepositoryName = 'vmware-powercli-for-vmware-cloud-disaster-recovery'
  $RepositoryOwner = 'vmware'
  $secureString = ($GitHubApiKey | ConvertTo-SecureString -AsPlainText -Force)
  $cred = New-Object System.Management.Automation.PSCredential 'username is ignored', $secureString
  Set-GitHubAuthentication -Credential $cred
  if ($Prerelease)
  {
    $IsPrerelease = $true
    $TagVersion = "$Version-$Prerelease"
  }
  else
  {
    $IsPrerelease = $false
    $TagVersion = $Version
  }
  if ($Publish)
  { 
    $Release = New-GitHubRelease -OwnerName $RepositoryOwner -RepositoryName $RepositoryName -Tag $TagVersion -PreRelease:$IsPrerelease 
    $Release | New-GitHubReleaseAsset -Path $DestZip 
    $Release | Format-Table
  }
  else
  {
    Write-Output "To release on github run:`n   New-GitHubRelease -OwnerName ""$RepositoryOwner"" -RepositoryName ""$RepositoryName"" -Tag ""$TagVersion"" -PreRelease:`$$IsPrerelease |New-GitHubReleaseAsset  -Path ""$DestZip"""
  }
}
#endregion GitHub

Write-Output "`nDone.`n"
Write-Output "To install locally for debug use, execute: .\install.ps1 -Install CurrentUser`n"