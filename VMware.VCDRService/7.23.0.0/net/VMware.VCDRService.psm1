﻿#################################################################################
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

class AWSRegions : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {  
            return $Script:AwsActiveRegion
    }
}

update-TypeData -TypeName "VMware.VCDRService.ProtectionGroup" -DefaultDisplayPropertySet Name, Health, used_gib
update-TypeData -TypeName "VMware.VCDRService.ProtectionGroupSnapshot" -DefaultDisplayPropertySet   Name , vm_count, failed_vm_snap_count, total_used_data_gib
update-TypeData -TypeName "VMware.VCDRService.CloudFileSystem" -DefaultDisplayPropertySet   Name , Capacity_gib, Used_gib
update-TypeData -TypeName "VMware.VCDRService.ProtectedSite" -DefaultDisplayPropertySet   Name , Type
update-TypeData -TypeName "VMware.VCDRService.VCDRServer" -DefaultDisplayPropertySet Server , Version, OrgId, Region
update-TypeData -TypeName "VMware.VCDRService.VmSummary" -DefaultDisplayPropertySet Name, Size, Vcdr_vm_id
update-TypeData -TypeName "VMware.VCDRService.RecoverySddc"  -DefaultDisplayPropertySet Name, Region, Availability_zones
update-TypeData -TypeName "VMware.VCDRService.VCDRService" -DefaultDisplayPropertySet OrgId,VcdrInstances
update-TypeData -TypeName "VMware.VCDRService.VcdrSummary" -DefaultDisplayPropertySet Id,Url,Region

New-Variable -Scope Script -Name DefaultVCDRService 
New-Variable -Scope Script -option Constant -Name AWSRegions -value @('us-east-2','us-east-1','us-west-1','us-west-2','af-south-1','ap-east-1','ap-southeast-3','ap-south-1','ap-northeast-3','ap-northeast-2','ap-southeast-1','ap-southeast-2','ap-northeast-1','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-south-1','eu-west-3','eu-north-1','me-south-1','sa-east-1')
New-Variable -Scope Script -name AwsActiveRegion -Value $AWSRegions
New-Variable -Scope Script -Name PagingSize -Value 100


<#
    .SYNOPSIS
        This cmdlet establishes a connection to a VCDR Service.
    .DESCRIPTION
            This cmdlet establishes a connection to a VCDR Service. The cmdlet starts a new session or re-establishes
    a previous session with a VCDR Server system using the specified parameters.
    .PARAMETER Name
        The name of the Cloud File System
    .PARAMETER Id
        The identifier of the cloud file system.
    .EXAMPLE
        $token="<my VMC TOKEN>"
            
        $VCDR=Connect-VCDRService -token $token

        Description
        -----------
        This example connect to a VCDR Service  using a VMC token


    .NOTES
        FunctionName    : Connect-VCDRService
        Created by      : VMware
        Date Coded      : 2022/02/20
        Modified by     : VMware
        Date Modified   : 2022/02/20 16:12:10
        More info       : https://vmware.github.com/
    .LINK

#>
Function Connect-VCDRService {
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory = $true)]
        [String]  $Token, 
        [Parameter( Mandatory = $false)]
        [ValidateSet([AWSRegions],ErrorMessage="Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region, 
        [String] $cspBaseUrl ,
        [String] $vcdrBackendUrl  
    )
    Begin { 
    }
    Process {
            if ($Script:DefaultVCDRService){
                if ($Script:DefaultVCDRService.CompareToken($Token)){
                    throw "Already connected to Org:"+$Script:DefaultVCDRService.OrgId+ " . Use Disconnect-VCDRService to disconnect from this Org."
                }
                $Script:DefaultVCDRService.Disconnect
            } 
            [VMware.VCDRService.VCDRService] $VCDRServiceClient = New-Object VMware.VCDRService.VCDRService($Token, $cspBaseUrl,$vcdrBackendUrl) 
            Set-Variable -Scope Script -name DefaultVCDRService -value $VCDRServiceClient
            $Script:AwsActiveRegion = $VCDRServiceClient.GetActiveRegions();
        }
    
    End { 
        return $VCDRServiceClient
    }
}


<#
    .SYNOPSIS
        This cmdlet closes the connection to a VCDR Service .
    .DESCRIPTION
            This cmdlet closes the connection to a VCDR Service .   

    .EXAMPLE
        $token="<my VMC TOKEN>"
        $VCDR=Connect-VCDRService -token $token

        Disconnect-VCDRService   

        Description
        -----------
        This example connect to a VCDR Server system  using a VMC token.Then disconnects from the specified server.


    .NOTES
        FunctionName    : Disconnect-VCDRService
        Created by      : VMware
        Date Coded      : 2022/02/20
        Modified by     : VMware
        Date Modified   : 2022/02/20 16:12:10
        More info       : https://vmware.github.com/
    .LINK

#> 
Function Disconnect-VCDRService {      
    Begin {
    }
    Process {
        if ($Script:DefaultVCDRService){ 
            $Script:DefaultVCDRService.Disconnect()
            Remove-Variable -Scope Script -name DefaultVCDRService 
            Set-Variable -Scope Script -name AwsActiveRegion -value $AWSRegions
        }
    }
    End {
    }
}



 



Function Get-VCDRInstance {
    Begin { 
        $result = [VMware.VCDRService.VcdrSummary[]]@()
    }
    Process {
        $result = $DefaultVCDRService.GetVcdrInstances()
       
    }
    End {
        return $result
    }
}




Function Set-DefaultVCDRInstance {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
   #           [OutputType([VMware.VCDRService.VcdrSummary[]])]
   [Parameter( Mandatory = $True)]
   [ValidateSet([AWSRegions],ErrorMessage="Value '{0}' is not a valid region. Try one of: {1}")]
   [String] $Region
      Begin {  
      }
      Process {
          $Server = $DefaultVCDRService.SelectRegion($Region)
          $result=  New-Object -TypeName "VMware.VCDRService.VcdrSummary" -ArgumentList $Server
      }
      End {
          return $result
      }
  }

  Function Get-DefaultVCDRInstance { 
      Begin {  
      }
      Process {
          $Server = $DefaultVCDRService.ActiveVcdrInstance
          $result=  New-Object -TypeName "VMware.VCDRService.VcdrSummary" -ArgumentList $Server         
      }
      End {
          return $result
      }
  }

  

 
 
<#
        .SYNOPSIS
            List of cloud file systems
        .DESCRIPTION
            Get a list of any deployed cloud file systems in your VMware Cloud DR organization with details.
        .PARAMETER Region
            Specifies the region on which you want to run the cmdlet. If no value is provided to this parameter, the command runs on the default region.
        .PARAMETER Name
           The name of the Cloud File System
        .PARAMETER Id
            The identifier of the cloud file system.
        .EXAMPLE
            Get-VCDRCloudFileSystem -Name "cloud-backup-1"

            Description
            -----------
            This example shows recalling of any Cloud Files System that matches the given name
        
            .EXAMPLE
            Get-VCDRCloudFileSystem -Region us-west-2

            Description
            -----------
            This example shows recalling of any Cloud Files System residing in us-west-2 region

        .EXAMPLE
            Get-VCDRCloudFileSystem -Id "dbd913aa-6cbe-11ec-9871-0a3e56ef2005"

            Description
            -----------
            This example shows recalling of any Cloud Files System that matches the given id
        .NOTES
            FunctionName    : Get-VCDRCloudFileSystem
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
Function Get-VCDRCloudFileSystem {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.CloudFileSystem[]])]
    Param( 
        [Parameter( Mandatory = $false)]
        [ValidateSet([AWSRegions],ErrorMessage="Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region,
        [Parameter( Mandatory = $false, ParameterSetName = "ByName", HelpMessage = "The name of the Cloud File System ")]
        [String]  $Name ,
        [Parameter( Mandatory = $false, ParameterSetName = "ById", HelpMessage = "The identifier of the cloud file system.")]
        [String]  $Id
    )
    Begin { 
        if ($DefaultVCDRService) { 
            $Server = $DefaultVCDRService.SelectRegion($Region)
        } else {
            throw "No Server connected"
        } 
        $result = [VMware.VCDRService.CloudFileSystem[]]@()
    }
    Process {
        $cfs = $Server.GetCloudFileSystems()
        if ($cfs.Cloud_file_systems) {
            if ($name) {
                $cf = $cfs.Cloud_file_systems | Where-Object { $_.Name -eq $Name }
                if ($cf) {
                    $result += $Server.GetCloudFileSystemDetails($cf.id)
                }
            }
            elseif ($id) {
                $cf = $cfs.Cloud_file_systems | Where-Object { $_.Id -eq $id }
                if ($cf) {
                    $result += $Server.GetCloudFileSystemDetails($cf.id)
                }
            }
            else {
                foreach ($cf in $cfs.Cloud_file_systems) {
                    $result += $Server.GetCloudFileSystemDetails($cf.Id)
                }
            }
        }
    }
    End {
        return $result
    }
}


<#
        .SYNOPSIS
            List of protected sites.
        .DESCRIPTION
            Get a list of all protected sites associated with an individual cloud file system with details.
            A protected site is a logical grouping of vCenters with VMs that are "protected" by the DRaaS Connector using snapshot replication to a cloud file system.
            A protected site is associated with a unique cloud file system.
       .PARAMETER CloudFileSystem
            Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system for which you want to get a list of all protected sites.
        .PARAMETER Vcenter
            Unique identifier(s) of one or more vCenter(s)
        .PARAMETER ProtectionGroup
            Unique identifier(s) of one or more Protection Group(s)
        .EXAMPLE
            $CloudFS=Get-VCDRProtectedSite -CloudFileSystem "dbd913aa-6cbe-11ec-9871-0a3e56ef2005"
            Get-VCDRProtectedSite -CloudFileSystem $CloudFS

            Description
            -----------
            This example shows list any protected site protected by the Cloud Files System dbd913aa-6cbe-11ec-9871-0a3e56ef2005

        .NOTES
            FunctionName    : Get-VCDRProtectedSite
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>

Function Get-VCDRProtectedSite {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.ProtectedSite[]])]
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Cloud FileSystem")]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem,
        [Parameter( Mandatory = $false, HelpMessage = "vCenter")]
        [String[]]  $Vcenter ,
        [Parameter( Mandatory = $false, HelpMessage = "Protection Group")]
        [String[]]  $ProtectionGroup     

    )
    Begin {
        if ($DefaultVCDRService) {   
            $result = [VMware.VCDRService.ProtectedSite[]]@()

            $protectedSitesFilterSpec = New-Object -TypeName  'VMware.VCDRService.ProtectedSitesFilterSpec'
            $protectedSitesFilterSpec.Protection_group_ids = new-object -typename System.Collections.Generic.List[String]
            $protectedSitesFilterSpec.Vcenter_ids = new-object -typename System.Collections.Generic.List[String]

            if ($ProtectionGroup) {
                foreach ($item in $ProtectionGroup) {
                    $protectedSitesFilterSpec.Protection_group_ids.Add($item)
                }
            }
            if ($Vcenter) {
                foreach ($item in $Vcenter) {
                    $protectedSitesFilterSpec.Vcenter_ids.Add($item)
                }
            }
        } else {
            throw "No Server connected"
        } 
    }
    Process {
        foreach($Cfs in $CloudFileSystem) {
            $Server = $Cfs.Server 
            [String]   $Cursor = $Null
            $protectedSites = [VMware.VCDRService.GetProtectedSitesResponse[]]@()
            do {
                $protectedSitesResponse = $Server.GetProtectedSites($Cfs, $PagingSize, $protectedSitesFilterSpec, $Cursor)
                if (! $protectedSitesResponse) {
                    break
                }
                $protectedSites += $protectedSitesResponse.Protected_sites
                $Cursor = $protectedSitesResponse.Cursor
            }  while ($Cursor -and $protectedSitesResponse.Protected_sites -gt 0 )

            foreach ($ps in $protectedSites) {
                $result += $Server.GetProtectedSiteDetails($Cfs, $ps.Id)
            }
        }
    }
    End {
        return $result
    }
}



<#
        .SYNOPSIS
            List of any protection groups associated with an individual cloud file system.
        .DESCRIPTION
            Get a detailed list of all protection groups associated with an individual cloud file system
            A protection group defines a collection of VMs on a protected site that are being snapshotted and replicated to a cloud file system.
            A protection group is associated with exactly one protected site (and by extension, exactly one cloud file system).
       .PARAMETER CloudFileSystem
            Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system for which you want to get a list of all protected sites
        .PARAMETER vCenter
           List of vCenters ID to be used as filter
        .PARAMETER Site
             List of Sites ID to be used as filter
        .EXAMPLE
            $cloudFileSystem=Get-VCDRCloudFileSystem -name "cloud-backup-1"
            $ProtectionGroups=Get-VCDRProtectionGroup  -CloudFileSystem $cloudFileSystem

            Description
            -----------
            This example shows  any  protecion groups associated with the cloud file system

        .NOTES
            FunctionName    : Get-VCDRProtectionGroup
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
Function Get-VCDRProtectionGroup {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.ProtectionGroup[]])]
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Cloud FileSystem")]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem,
        [Parameter( Mandatory = $false, HelpMessage = "vCenter ID")]
        [String[]]  $Vcenter ,
        [Parameter( Mandatory = $false, HelpMessage = "Site ID")]
        [String[]]  $Site  
    )
    Begin { 
        if ($DefaultVCDRService) {  
            $result = [VMware.VCDRService.ProtectionGroup[]]@()

            $protectionGroupsFilterSpec = New-Object -TypeName  'VMware.VCDRService.ProtectionGroupsFilterSpec'
            $protectionGroupsFilterSpec.Site_ids = new-object -typename System.Collections.Generic.List[String]
            $protectionGroupsFilterSpec.Vcenter_ids = new-object -typename System.Collections.Generic.List[String]

            if ($Site) {
                foreach ($item in $Site) {
                    $protectionGroupsFilterSpec.Site_ids.Add($item)
                }
            }
            if ($Vcenter) {
                foreach ($item in $Vcenter) {
                    $protectionGroupsFilterSpec.Vcenter_ids.Add($item)
                }
            } 
        } else {
            throw "No Server connected"
        }
    }
    Process {
        foreach($Cfs in $CloudFileSystem) {            
            $Server = $CloudFileSystem.Server 
            $protectedGroups = [VMware.VCDRService.GetProtectionGroupsResponse[]]@()
            [String]   $Cursor = $Null
            do {
                $protectedGroupsResponse = $Server.GetProtectionGroups($Cfs, $PagingSize, $protectionGroupsFilterSpec, $Cursor)
                if (!$protectedGroupsResponse.Protection_groups ) { break }
                $protectedGroups += $protectedGroupsResponse.Protection_groups
                $Cursor = $protectedGroupsResponse.Cursor
            }  while ($Cursor -and $protectedGroupsResponse.Protection_groups -gt 0 )

            foreach ($ps in $protectedGroups) {
                $result += $Server.GetProtectionGroupDetails($Cfs, $ps.Id)
            }
        }  
    }
    End {
        return $result
    }
}


<#
        .SYNOPSIS
            List of any snpashots associated to a specific protection group.
        .DESCRIPTION
            Get a list of all snpashots in a specific protection group.
            A protection group snapshot encodes the point-in-time state of all the VMs defined in a specific protection group.
            Protection group snapshots are immutable but are deleted when they expire, or when the containing protection group is deleted. A protection group snapshot is associated with exactly one protection group..
        .PARAMETER ProtectionGroup
            Unique identifier(s) of one or more Protection Group(s)
        .EXAMPLE
            $cloudFileSystem=Get-VCDRCloudFileSystem -name "cloud-backup-1"
            $ProtectionGroups=Get-VCDRProtectionGroup  -CloudFileSystem $cloudFileSystem
            Get-VCDRSnapshot  -ProtectionGroup $ProtectionGroups

            Description
            -----------
            This example shows  any  snapshot in the protection group

        .NOTES
            FunctionName    : Get-VCDRSnapshot
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
Function Get-VCDRSnapshot {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.ProtectionGroupSnapshot[]])]
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Protection Groups")]
        [VMware.VCDRService.ProtectionGroup[] ]  $ProtectionGroups,
        [Parameter( Mandatory = $false, HelpMessage = "Snapshot Id")]
        [String ]  $SnapshotID
    )
    Begin { 
        if ($DefaultVCDRService) {  
            $result = [VMware.VCDRService.ProtectionGroupSnapshot[]]@()
        } else {
            throw "No Server connected"
        }
    }
    Process {

        if ( $SnapshotID ) {
            foreach ($ProtectionGroup in  $ProtectionGroups) {
                $Server = $ProtectionGroup.Server
                $result += $Server.GetProtectionGroupSnapshotDetails($ProtectionGroup, $SnapshotID)
            }
        } else {

            foreach ($ProtectionGroup in  $ProtectionGroups) {
                $Server = $ProtectionGroup.Server
                $ProtectionGroup.CloudFileSystem.Id
                [String] $Cursor = $Null
                $Snapshots = [VMware.VCDRService.GetProtectionGroupSnapshotsResponse[]]@()
                do {
                    $protectionGroupSnapshotResponse = $Server.GetProtectionGroupSnapshots( $ProtectionGroup, $PagingSize, $Cursor)
                    if (!$protectionGroupSnapshotResponse) { break }
                    if (!$protectionGroupSnapshotResponse.Snapshots) { break }
                    $Cursor = $protectionGroupSnapshotResponse.Cursor
                    $Snapshots += $protectionGroupSnapshotResponse.Snapshots
                }  while ($Cursor -and $protectionGroupSnapshotResponse.Snaphsots -gt 0 )
                foreach ($ps in $Snapshots) {
                    $result += $Server.GetProtectionGroupSnapshotDetails($ProtectionGroup, $ps.Id)
                }
            }
        }
    }
    End {
        return $result
    }
}






<#
        .SYNOPSIS
            List of VMs associated with an individual cloud file system
        .DESCRIPTION
          A "protected" VM is a VM that is contained in at least one protection group snapshot that has been replicated to a cloud file system.
       .PARAMETER CloudFileSystem
            Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system for which you want to get a list of all protected sites
        .PARAMETER vCenter
           List of vCenters ID to be used as filter
        .PARAMETER Site
             List of Sites ID to be used as filter
        .PARAMETER ProtectionGroup
           List of protection groups to be used as filter
        .EXAMPLE
            $cloudFileSystem=Get-VCDRCloudFileSystem -name "cloud-backup-1"
            $Vms=Get-VCDRProtectedVm  -CloudFileSystem $cloudFileSystem

            Description
            -----------
            This example shows  any  protecion groups associated with the cloud file system

        .NOTES
            FunctionName    : Get-VCDRProtectedVm
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
Function Get-VCDRProtectedVm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.VmSummary[]])]
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Cloud FileSystem")]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem,
        [Parameter( Mandatory = $false, HelpMessage = "vCenter ID")]
        [String[]]  $Vcenter ,
        [Parameter( Mandatory = $false, HelpMessage = "Site ID")]
        [String[]]  $Site ,
        [Parameter( Mandatory = $false, HelpMessage = "Protection Group ID")]
        [VMware.VCDRService.ProtectionGroup[]]  $ProtectionGroup ,
        [Parameter( Mandatory = $false, HelpMessage = "Protection Group Snapshot ID")]
        [VMware.VCDRService.ProtectionGroupSnapshot[]] $ProtectionGroupSnapshot 
    )
    Begin {
        if ($DefaultVCDRService) {  
            $result = [VMware.VCDRService.VmSummary[]]@()

            $VmsFilterSpec = New-Object -TypeName  'VMware.VCDRService.VmsFilterSpec'
            $VmsFilterSpec.Site_ids = new-object -typename System.Collections.Generic.List[String]
            $VmsFilterSpec.Vcenter_ids = new-object -typename System.Collections.Generic.List[String]
            $VmsFilterSpec.Protection_group_snapshot_id = new-object -typename System.Collections.Generic.List[String]
            $VmsFilterSpec.Protection_group_ids = new-object -typename System.Collections.Generic.List[String]

            if ($Site) {
                foreach ($item in $Site) {
                    $VmsFilterSpec.Site_ids.Add($item)
                }
            }
            if ($Vcenter) {
                foreach ($item in $Vcenter) {
                    $VmsFilterSpec.Vcenter_ids.Add($item)
                }
            }
            if ($ProtectionGroup) {
                foreach ($pg in $ProtectionGroup) {
                    $VmsFilterSpec.Protection_group_ids.Add($pg.id)
                }
            }

            if ($ProtectionGroupSnapshot) {
                foreach ($pgs in $ProtectionGroupSnapshot) {
                    $VmsFilterSpec.Protection_group_snapshot_id.Add($pgs.Id)
                }
            }
        } else {
            throw "No Server connected"
        }
    }
    Process {
        foreach($Cfs in $CloudFileSystem) {  
            $Server = $CloudFileSystem.Server 
            [String] $Cursor = $Null
            do {
                $protectedVirtualMachines = $Server.GetProtectedVirtualMachines($Cfs, $PagingSize, $VmsFilterSpec, $Cursor)
                if (!$protectedVirtualMachines) { break }
                if (!$protectedVirtualMachines.Vms ) { break }
                $result += $protectedVirtualMachines.Vms
                $Cursor = $protectedVirtualMachines.Cursor
            }  while ($Cursor -and $protectedVirtualMachines.Vms.Count -gt 0 )
        } 
    }
    End {
        return $result
    }
}



<#
        .SYNOPSIS
            List of Recovery SDDCs
        .DESCRIPTION
            A Recovery SDDC is a VMware Cloud (VMC) software-defined datacenter (SDDC) where protected VMs are created, configured, and powered on during VMware Cloud DR failover.
        .PARAMETER Region
            Specifies the region on which you want to run the cmdlet. If no value is provided to this parameter, the command runs on the default region.
        .PARAMETER Name
           The name of the Sddc
        .PARAMETER Id
            The identifier of the Sddc.
        .EXAMPLE
            Get-VCDRRecoverySddc -Name "cloud-backup-SDDC"

            Description
            -----------
            This example shows the information of the SDDC that matches the given name

        .EXAMPLE
            Get-VCDRRecoverySddc

            Description
            -----------
            This example shows the information of the any SDDC
         .NOTES
            FunctionName    : Get-VCDRRecoverySddc
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
Function Get-VCDRRecoverySddc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.RecoverySddc[]])]
    Param(
        [Parameter( Mandatory = $false)]
        [ValidateSet([AWSRegions],ErrorMessage="Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region,
        [Parameter( Mandatory = $false, ParameterSetName = "ByName", HelpMessage = "The name of the Recovery SDDC ")]
        [String]  $Name ,
        [Parameter( Mandatory = $false, ParameterSetName = "ById", HelpMessage = "The identifier of the Recovery SDDC.")]
        [String]  $Id  
    )
    Begin { 
        if ($DefaultVCDRService) { 
            $Server = $DefaultVCDRService.SelectRegion($Region)
        } else {
            throw "No Server connected"
        } 
        $result = [VMware.VCDRService.RecoverySddc[]]@()
    }
    Process {
        $rSddcs = $Server.GetRecoverySddc()
        if ($rSddcs.data) {
            if ($name) {
                $cf = $rSddcs.data | Where-Object { $_.Name -eq $Name }
                if ($cf) {
                    $result += $Server.GetRecoverySddcDetails($cf.id)
                }
            }
            elseif ($id) {
                $cf = $rSddcs.data | Where-Object { $_.Id -eq $id }
                if ($cf) {
                    $result += $Server.GetRecoverySddcDetails($cf.id)
                }
            }
            else {
                foreach ($cf in $rSddcs.data) {
                    $result += $Server.GetRecoverySddcDetails($cf.Id)
                }
            }
        }
        return $result
    }
    End {
    }
} 

Export-ModuleMember -Function Connect-VCDRService
Export-ModuleMember -Function Disconnect-VCDRService
Export-ModuleMember -Function Get-VCDRInstance 
Export-ModuleMember -Function Get-DefaultVCDRInstance
Export-ModuleMember -Function Set-DefaultVCDRInstance
Export-ModuleMember -Function Get-VCDRCloudFileSystem
Export-ModuleMember -Function Get-VCDRProtectedSite
Export-ModuleMember -Function Get-VCDRProtectionGroup
Export-ModuleMember -Function Get-VCDRSnapshot
Export-ModuleMember -Function Get-VCDRProtectedVm
Export-ModuleMember -Function Get-VCDRRecoverySddc