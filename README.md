# PowerShell cmdlets for VMware Cloud Disaster Recovery

# What is VMware PowerCLI for VMware Cloud Disaster Recovery
PowerCLI for VCDR is a PowerShell module that abstracts the VMware Cloud Disaster Recovery API to a set of easily used PowerShell functions.

The backend of these Cmdlets (VCDR API) is still in the beta phase, and as a consequence of that, this module is not currently supported by VMware and comes with no warranties, express or implied. Please test and validate its functionality before using this product in a production environment.

**Requirement:**
- Powershell at least 7.2.0: https://github.com/powershell/powershell
- Operative System supported - more info at https://github.com/dotnet/core/blob/main/release-notes/3.1/3.1-supported-os.md

| Type | OS |
| ------ | ------ |
| Windows | Any no EOL Windows (x64), Windows (x86)   |
| Ubuntu | Ubuntu 20.04, Ubuntu 18.04, Ubuntu 16.04 |
| Debian | Debian 9, Debian 10, Debian 11 |
| Centos | CentOS 7,CentOS 8 |
| Red Hat | Red Hat Enterprise Linux 7, Red Hat Enterprise Linux 8 |
| OpenSuse | openSUSE 42.3 |
| Fedora | Fedora 35+ |
| MACOSX | macOS 10.13+ (x64), macOS 10.13+ (arm64)	|

**Installation** 

**Using PowerShell Gallery** 
```Install-Module -Name VMware.VCDRService```

**Using GitHub code**

First steps 
1. Install .Net runtime and PowerShell
2. Open PowerShell Core (pwsh) or Windows PowerShell (powershell.exe)
3. Change the active directory to **\vcdr-powershell-cmdlet**
4. run **.\install.ps1 -Install CurrentUser**   
5. **Connect-VCDRService**  **-token** "your VMC token" 

**Get-Help** is available for each cmdlet
 
<details><summary>  CmdLets  </summary>

- Connect-VCDRService
- Disconnect-VCDRService
- Get-VCDRInstance
- Set-DefaultVCDRInstance
- Get-DefaultVCDRInstance
- Get-VCDRCloudFileSystem
- Get-VCDRProtectedSite
- Get-VCDRProtectionGroup
- Get-VCDRSnapshot
- Get-VCDRProtectedVm
- Get-VCDRRecoverySddc
</details>

An introduction to the VCDR PowerShell CmdLets is available here https://vmc.techzone.vmware.com/getting-started-powercli-vmware-cloud-disaster-recovery 

**Sample scripts**

_Script-1_
```
$token=_"your VMC token" 
Connect-VCDRService  -token $token
$RecoverySDDC=Get-VCDRRecoverySDDC 
$cloudFileSystem=Get-VCDRCloudFileSystem 
$ProtectedSites=Get-VCDRProtectedSite -CloudFileSystem $cloudFileSystem
$ProtectionGroups=Get-VCDRProtectionGroup  -CloudFileSystem $cloudFileSystem
$Snapshots=Get-VCDRSnapshot -ProtectionGroups $ProtectionGroups
$Vms=Get-VCDRProtectedVm -CloudFileSystem $cloudFileSystem
Disconnect-VCDRService
``` 

_Script-2_
```
$token=_"your VMC token" 
Connect-VCDRService -token $token 

#Return any Protection Site or each CloudFileSystem
Get-VCDRCloudFileSystem| Get-VCDRProtectedSite  

#Return any Protection Group or each CloudFileSystem
Get-VCDRCloudFileSystem|Get-VCDRProtectionGroup  

#Return any Snapshot for each CloudFileSystem
Get-VCDRCloudFileSystem|Get-VCDRProtectionGroup|Get-VCDRSnapshot 

#Return any Protected VM for each CloudFileSystem
Get-VCDRCloudFileSystem|Get-VCDRProtectedVm  

Disconnect-VCDRService

```


A test script called **.\start-VCDRTest.ps1** is available 
```
.\start-VCDRTest.ps1 -token "<my VMC TOKEN>"
```
***


**Build**

The only supported build platform is Microsoft Windows 10/11. In theory MACOSX should works using Visual Studio for MACOSX (never tested)

**Required:** 
- NSWAG:https://github.com/RicoSuter/NSwag
- Visual Studio 2022:https://visualstudio.microsoft.com/downloads/ 

**Steps**
- CMD Route 
    1. Open the **x64 Native Tools Command Prompt for VS 2022**
    2. Change the active directory to **\vcdr-powershell-cmdlet**
    3. run **build.cmd** 
    4. The new cmdlets should be available in **\vcdr-powershell-cmdlet\VMware.VCDRService\**
    5. To install follow the Installation steps
- PowerShell Route 
    1. Open the **Developer PowerShell for VS 2022**
    2. Change the active directory to **\vcdr-powershell-cmdlet**
    3. run **.\build.ps1** 
    4. The new cmdlets should be available in **\vcdr-powershell-cmdlet\VMware.VCDRService\**
    5. To install follow the Installation steps

**Replace YAML file**
1. Copy the new YAML file to **\NSWAG\vcdr.yaml
2. Change the active directory to **\vcdr-powershell-cmdlet**
3. Depends on what shell are you using execute **build.cmd** or **.\build.ps1** 
4. The new cmdlets are available in **\vcdr-powershell-cmdlet\VMware.VCDRService\**
5. To install follow the Installation steps



**Important !!!!!** 

**build.cmd** and **.\build.ps1** are going to replace any powershell scripts and c# code for .NET4.7, with the corrispondent code for core.NET. Any change to the source code should be apply to the Core.NET code



# Contributing

The vmware-powercli-for-vmware-cloud-disaster-recovery project team welcomes contributions from the community. Before you start working with container-service-extension-templates, please read our Developer Certificate of Origin. All contributions to this repository must be signed as described on that page. Your signature certifies that you wrote the patch or have the right to pass it on as an open-source patch. For more detailed information, refer to CONTRIBUTING.md.
