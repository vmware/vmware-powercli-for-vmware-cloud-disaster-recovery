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

class AWSRegions : System.Management.Automation.IValidateSetValuesGenerator
{
    [String[]] GetValidValues()
    {  
        return $Script:AwsActiveRegion
    }
}

class HFSFilter 
{
    [String ]$VendorId  
    [String ]$DiskUuid  
    [String ]$FileName 
    HFSFilter (  $VendorId, $DiskUuid, $FileName)
    {
        $this.VendorId = $VendorId
        $this.DiskUuid = $DiskUuid 
        $this.FileName = $FileName
    }
} 

New-Variable -Scope Script -Name DefaultVCDRService 
New-Variable -Scope Script -Option Constant -Name AWSRegions -Value @('us-east-2', 'us-east-1', 'us-west-1', 'us-west-2', 'af-south-1', 'ap-east-1', 'ap-southeast-3', 'ap-south-1', 'ap-northeast-3', 'ap-northeast-2', 'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'ca-central-1', 'eu-central-1', 'eu-west-1', 'eu-west-2', 'eu-south-1', 'eu-west-3', 'eu-north-1', 'me-south-1', 'sa-east-1', 'unknow')
New-Variable -Scope Script -Name AwsActiveRegion -Value $AWSRegions
New-Variable -Scope Script -Name PagingSize -Value 100
New-Variable -Scope Script -Option Constant -Name NotConnectedMsg -Value 'You are not currently connected to any servers. Please connect first using a Connect cmdlet.'

<#
    .SYNOPSIS
        This cmdlet establishes a connection to a VCDR Service.
    .DESCRIPTION
            This cmdlet establishes a connection to a VCDR Service. The cmdlet starts a new session or re-establishes
    a previous session with a VCDR Server system using the specified parameters.
    .PARAMETER Token
        The tokne used to authenticate VMC
    .PARAMETER Region
        The Region set as default for any cmdlet operation
    .PARAMETER Server
        The Server set as default for any cmdlet operation (alternative connection)
    .PARAMETER cspBaseUrl
        Specifies the IP address or the DNS name of the VMware managed cloud service. If not specified, the cmdlet assumes that you are connecting to the public commercial instance and the default value of
        `vmc.vmware.com` is used
    .PARAMETER vcdrBackendUrl
        Specifies the IP address or the DNS name of the VMware managed disaster recovery cloud service. If not specified, the cmdlet assumes that you are connecting to the public commercial instance and the default value of
        `vdp.vmware.com` is used
    .EXAMPLE 
        $token="<my VMC TOKEN>"
            
        $VCDR=Connect-VCDRService -token $token

        Description
        -----------
        This example connect to a VCDR Service  using a VMC token


    .NOTES
        FunctionName    : Connect-VCDRService
        Created by      : VMware
        Modified by     : VMware
        Date Modified   : 2022/08/01 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#>
Function Connect-VCDRService
{
    [OutputType([VMware.VCDRService.VCDRService])] 
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param(   
        [Parameter( Mandatory = $true, ParameterSetName = 'Default')] 
        [Parameter( Mandatory = $true, ParameterSetName = 'Host')]
        [String]  $Token, 
        [Parameter( Mandatory = $false, ParameterSetName = 'Default')]
        [ValidateSet([AWSRegions], ErrorMessage = "Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region, 
        
        [Parameter( Mandatory = $false, ParameterSetName = 'Host')]
        [Parameter( Mandatory = $false, ParameterSetName = 'Default')]
        [String] $cspBaseUrl ,
        
        [Parameter( Mandatory = $false, ParameterSetName = 'Default')]
        [String] $vcdrBackendUrl,
        
        [Parameter( Mandatory = $true, ParameterSetName = 'Host')]
        [String] $Server  
    ) 
    if ($Script:DefaultVCDRService)
    {
        #  if ($Script:DefaultVCDRService.CompareToken($Token))
        #  {
        #     throw 'Already connected to Org:' + $Script:DefaultVCDRService.OrgId + ' . Use Disconnect-VCDRService to disconnect from this Org.'
        #   }
        $Script:DefaultVCDRService.Disconnect
    }   
    if ($Server)
    {
        [System.Uri] $serverUri = [System.Uri]"https://$Server"
        [VMware.VCDRService.VCDRService] $VCDRServiceClient = New-Object VMware.VCDRService.VCDRService($Token, $serverUri, $cspBaseUrl) 
    }
    else
    {
        [VMware.VCDRService.VCDRService] $VCDRServiceClient = New-Object VMware.VCDRService.VCDRService($Token, $cspBaseUrl, $vcdrBackendUrl)   
    }
    Set-Variable -Scope Script -Name DefaultVCDRService -Value $VCDRServiceClient 
    $Script:AwsActiveRegion = $VCDRServiceClient.GetActiveRegions()
    return $VCDRServiceClient 
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
        Modified by     : VMware
        Date Modified   : 2022/08/01 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#> 
Function Disconnect-VCDRService
{  
    if ($Script:DefaultVCDRService)
    { 
        $Script:DefaultVCDRService.Disconnect()
        Remove-Variable -Scope Script -Name DefaultVCDRService 
        Set-Variable -Scope Script -Name AwsActiveRegion -Value $AWSRegions
    } 
}



 
<#
    .SYNOPSIS
        This cmdlet return the list of VCDR instances available in the Org .
    .DESCRIPTION
            This cmdlet return each VCDR Server instance on each available region.
    .PARAMETER Region
        Return the VCDR server for this specific region
    .EXAMPLE
        $token="<my VMC TOKEN>"
        $VCDR=Connect-VCDRService -token $token  
        Get-VCDRInstance

        Disconnect-VCDRService   

        Description
        -----------
        This example connect to a VCDR Server system  using a VMC token.Set the new default VCDR Server and then disconnects.


    .NOTES
        FunctionName    : Get-VCDRInstance
        Created by      : VMware
        
        Modified by     : VMware
        Date Modified   : 2022/08/01 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#> 
 
Function Get-VCDRInstance
{ 
    [OutputType([VMware.VCDRService.VcdrSummary[]])]
    param(
        [Parameter( Mandatory = $False)]
        [ValidateSet([AWSRegions], ErrorMessage = "Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region
    )
    if ($Script:DefaultVCDRService)
    {
        [VMware.VCDRService.VcdrSummary[]] $Result = @()    
        $Result = $Script:DefaultVCDRService.GetVcdrInstances($Region)
        return $Result
    }
    else
    {
        throw $NotConnectedMsg
    }
     
}




<#
    .SYNOPSIS
        This cmdlet set the default VCDR Server in the Org .
    .DESCRIPTION
            This cmdlet set the defult server.   
    .PARAMETER Region
        The Region set as default for any cmdlet operation
    .EXAMPLE
        $token="<my VMC TOKEN>"
        $VCDR=Connect-VCDRService -token $token  
        Set-DefaultVCDRInstance -Region eu-west-1

        Disconnect-VCDRService   

        Description
        -----------
        This example connect to a VCDR Server system  using a VMC token.Set the new default VCDR Server and then disconnects.


    .NOTES
        FunctionName    : Set-DefaultVCDRInstance
        Created by      : VMware
        
        Modified by     : VMware
        Date Modified   : 2022/08/01 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#> 

Function Set-DefaultVCDRInstance
{
    [OutputType([VMware.VCDRService.VcdrSummary])]
    [CmdletBinding(DefaultParameterSetName = 'Default')] 
    param(        
        [Parameter( Mandatory = $True)]
        [ValidateSet([AWSRegions], ErrorMessage = "Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region
    )
    if ($Script:DefaultVCDRService)
    {
        $Server = $Script:DefaultVCDRService.SelectRegion($Region)
        $Result = New-Object -TypeName 'VMware.VCDRService.VcdrSummary' -ArgumentList $Server    
        return $Result  
    }
    else
    {
        throw $NotConnectedMsg
    }
}


<#
    .SYNOPSIS
        This cmdlet return the default VCDR Server in the Org .
    .DESCRIPTION
            This cmdlet return the defult server.   

    .EXAMPLE
        $token="<my VMC TOKEN>"
        $VCDR=Connect-VCDRService -token $token -region us-west-2
        Get-DefaultVCDRInstance

        Disconnect-VCDRService   

        Description
        -----------
        This example connect to a VCDR Server system  using a VMC token.Return the default VCDR Server and then disconnects.


    .NOTES
        FunctionName    : Get-DefaultVCDRInstance 
        Created by      : VMware
        Modified by     : VMware
        Date Modified   : 2022/08/01 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#> 
Function Get-DefaultVCDRInstance
{  
    [OutputType([VMware.VCDRService.VcdrSummary])] 
    $Server = $Script:DefaultVCDRService.ActiveVcdrInstance
    if ($Script:DefaultVCDRService)
    { 
        $Result = New-Object -TypeName 'VMware.VCDRService.VcdrSummary' -ArgumentList $Server   
        return $Result    
    }
    else
    {
        throw $NotConnectedMsg
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
        Modified by     : VMware
        Date Modified   : 2022/08/01 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#>
Function Get-VCDRCloudFileSystem
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.CloudFileSystem[]])]
    Param( 
        [Parameter( Mandatory = $false)]
        [ValidateSet([AWSRegions], ErrorMessage = "Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region,
        [Parameter( Mandatory = $false, ParameterSetName = 'ByName', HelpMessage = 'The name of the Cloud File System ')]
        [String]  $Name ,
        [Parameter( Mandatory = $false, ParameterSetName = 'ById', HelpMessage = 'The identifier of the cloud file system.')]
        [String]  $Id
    )
    Begin
    { 
        if ($Script:DefaultVCDRService)
        { 
            $Server = $Script:DefaultVCDRService.SelectRegion($Region)
        }
        else
        {
            throw $NotConnectedMsg
        } 
        [VMware.VCDRService.CloudFileSystem[]]  $Result = @()
    }
    Process
    {
        $cfs = $Server.GetCloudFileSystems()
        if ($cfs.Cloud_file_systems)
        {
            if ($name)
            {
                $cf = $cfs.Cloud_file_systems | Where-Object { $_.Name -eq $Name }
                if ($cf)
                {
                    $Result += $Server.GetCloudFileSystemDetails($cf.id)
                }
            }
            elseif ($id)
            {
                $cf = $cfs.Cloud_file_systems | Where-Object { $_.Id -eq $id }
                if ($cf)
                {
                    $Result += $Server.GetCloudFileSystemDetails($cf.id)
                }
            }
            else
            {
                foreach ($cf in $cfs.Cloud_file_systems)
                {
                    $Result += $Server.GetCloudFileSystemDetails($cf.Id)
                }
            }
        }
    }
    End
    {
        return $Result
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
            Modified by     : VMware
            Date Modified   : 2022/08/01 
            More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
        .LINK

    #>

Function Get-VCDRProtectedSite
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([VMware.VCDRService.ProtectedSite[]])]
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Cloud FileSystem')]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem,
        [Parameter( Mandatory = $false , HelpMessage = 'vCenter')]
        [VMware.VimAutomation.Types.VIServer[]]   $Vcenter , 
        [Parameter( Mandatory = $false, HelpMessage = 'Protection Group')]
        [VMware.VCDRService.ProtectionGroupDetails[]]  $ProtectionGroup     

    )
    Begin
    {
        if ($Script:DefaultVCDRService)
        {   
            [VMware.VCDRService.ProtectedSite[]] $Result = @()

            $protectedSitesFilterSpec = New-Object -TypeName 'VMware.VCDRService.ProtectedSitesFilterSpec'
            $protectedSitesFilterSpec.Protection_group_ids = New-Object -TypeName System.Collections.Generic.List[String]
            $protectedSitesFilterSpec.Vcenter_ids = New-Object -TypeName System.Collections.Generic.List[String]

            if ($ProtectionGroup)
            {
                foreach ($item in $ProtectionGroup)
                {
                    $protectedSitesFilterSpec.Protection_group_ids.Add($item.Id)
                }
            }
            if ($Vcenter)
            {
                foreach ($item in $Vcenter)
                {
                    $protectedSitesFilterSpec.Vcenter_ids.Add($item.InstanceUuid)
                }
            }
        }
        else
        {
            throw $NotConnectedMsg
        } 
    }
    Process
    {
        foreach ($Cfs in $CloudFileSystem)
        {
            $Server = $Cfs.Server 
            [String]   $Cursor = $Null
            [VMware.VCDRService.ProtectedSiteSummary[]]$protectedSites = @()
            do
            {
                $protectedSitesResponse = $Server.GetProtectedSites($Cfs, $PagingSize, $protectedSitesFilterSpec, $Cursor)
                if (! $protectedSitesResponse)
                {
                    break
                }
                $protectedSites += $protectedSitesResponse.Protected_sites
                $Cursor = $protectedSitesResponse.Cursor
            }  while ($Cursor -and $protectedSitesResponse.Protected_sites -gt 0 )

            foreach ($ps in $protectedSites)
            {
                $Result += $Server.GetProtectedSiteDetails($Cfs, $ps.Id)
            }
        }
    }
    End
    {
        return $Result
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
            Modified by     : VMware
            Date Modified   : 2022/08/01 
            More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
        .LINK

    #>
Function Get-VCDRProtectionGroup
{
    [OutputType([VMware.VCDRService.ProtectionGroup[]])]
    [CmdletBinding()]    
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Cloud FileSystem')]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem,
        [Parameter( Mandatory = $false , HelpMessage = 'vCenter')]
        [VMware.VimAutomation.Types.VIServer[]]   $Vcenter , 
        [Parameter( Mandatory = $false, HelpMessage = 'Site ID')]
        [String[]]  $Site  
    )
    Begin
    { 
        if ($Script:DefaultVCDRService)
        {  
            [VMware.VCDRService.ProtectionGroup[]]   $Result = @()

            $protectionGroupsFilterSpec = New-Object -TypeName 'VMware.VCDRService.ProtectionGroupsFilterSpec'
            $protectionGroupsFilterSpec.Site_ids = New-Object -TypeName System.Collections.Generic.List[String]
            $protectionGroupsFilterSpec.Vcenter_ids = New-Object -TypeName System.Collections.Generic.List[String] 
            if ($Site)
            {
                foreach ($item in $Site)
                {
                    $protectionGroupsFilterSpec.Site_ids.Add($item)
                }
            }
            if ($Vcenter)
            {
                foreach ($item in $Vcenter)
                {
                    $protectionGroupsFilterSpec.Vcenter_ids.Add($item.InstanceUuid)
                }
            } 
        }
        else
        {
            throw $NotConnectedMsg
        }
    }
    Process
    {
        foreach ($Cfs in $CloudFileSystem)
        {            
            $Server = $CloudFileSystem.Server 
            [VMware.VCDRService.ProtectionGroupSummary[]] $protectedGroups = @()
            [String]   $Cursor = $Null
            do
            {
                $protectedGroupsResponse = $Server.GetProtectionGroups($Cfs, $PagingSize, $protectionGroupsFilterSpec, $Cursor)
                if (!$protectedGroupsResponse.Protection_groups ) { break }
                $protectedGroups += $protectedGroupsResponse.Protection_groups
                $Cursor = $protectedGroupsResponse.Cursor
            }  while ($Cursor -and $protectedGroupsResponse.Protection_groups -gt 0 )

            foreach ($ps in $protectedGroups)
            {
                $Result += $Server.GetProtectionGroupDetails($Cfs, $ps.Id)
            }
        }  
    }
    End
    {
        return $Result
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
            Modified by     : VMware
            Date Modified   : 2022/08/01 
            More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
        .LINK

    #>
Function Get-VCDRSnapshot
{
    [OutputType([VMware.VCDRService.ProtectionGroupSnapshot[]])]
    [CmdletBinding()]     
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Protection Groups')]
        [VMware.VCDRService.ProtectionGroup[] ]  $ProtectionGroups,
        [Parameter( Mandatory = $false, HelpMessage = 'Snapshot Id')]
        [String ]  $SnapshotID
    )
    Begin
    { 
        if ($Script:DefaultVCDRService)
        {  
            [VMware.VCDRService.ProtectionGroupSnapshot[]]$Result = @()
        }
        else
        {
            throw $NotConnectedMsg
        }
    }
    Process
    {

        if ( $SnapshotID )
        {
            foreach ($ProtectionGroup in  $ProtectionGroups)
            {
                $Server = $ProtectionGroup.Server
                $Result += $Server.GetProtectionGroupSnapshotDetails($ProtectionGroup, $SnapshotID)
            }
        }
        else
        {

            foreach ($ProtectionGroup in  $ProtectionGroups)
            {
                $Server = $ProtectionGroup.Server 
                [String] $Cursor = $Null
                $Snapshots = [VMware.VCDRService.GetProtectionGroupSnapshotsResponse[]]@()
                do
                {
                    $protectionGroupSnapshotResponse = $Server.GetProtectionGroupSnapshots( $ProtectionGroup, $PagingSize, $Cursor)
                    if (!$protectionGroupSnapshotResponse) { break }
                    if (!$protectionGroupSnapshotResponse.Snapshots) { break }
                    $Cursor = $protectionGroupSnapshotResponse.Cursor
                    $Snapshots += $protectionGroupSnapshotResponse.Snapshots
                }  while ($Cursor -and $protectionGroupSnapshotResponse.Snaphsots -gt 0 )
                foreach ($ps in $Snapshots)
                {
                    $Result += $Server.GetProtectionGroupSnapshotDetails($ProtectionGroup, $ps.Id)
                }
            }
        }
    }
    End
    {
        return $Result
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
            Modified by     : VMware
            Date Modified   : 2022/08/01 
            More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
        .LINK

    #>
Function Get-VCDRProtectedVm
{
    [OutputType([VMware.VCDRService.VmSummary[]])]
    [CmdletBinding()] 
    Param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Cloud FileSystem')]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem,
        [Parameter( Mandatory = $false , HelpMessage = 'vCenter')]
        [VMware.VimAutomation.Types.VIServer[]]   $Vcenter , 
        [Parameter( Mandatory = $false, HelpMessage = 'Site ID')]
        [String[]]  $Site ,
        [Parameter( Mandatory = $false, HelpMessage = 'Protection Group ID')]
        [VMware.VCDRService.ProtectionGroup[]]  $ProtectionGroup ,
        [Parameter( Mandatory = $false, HelpMessage = 'Protection Group Snapshot ID')]
        [VMware.VCDRService.ProtectionGroupSnapshot[]] $ProtectionGroupSnapshot 
    )
    Begin
    {
        if ($Script:DefaultVCDRService)
        {  
            [VMware.VCDRService.VmSummary[]]$Result = @()

            $VmsFilterSpec = New-Object -TypeName 'VMware.VCDRService.VmsFilterSpec'
            $VmsFilterSpec.Site_ids = New-Object -TypeName System.Collections.Generic.List[String]
            $VmsFilterSpec.Vcenter_ids = New-Object -TypeName System.Collections.Generic.List[String]
            $VmsFilterSpec.Protection_group_snapshot_id = New-Object -TypeName System.Collections.Generic.List[String]
            $VmsFilterSpec.Protection_group_ids = New-Object -TypeName System.Collections.Generic.List[String]

            if ($Site)
            {
                foreach ($item in $Site)
                {
                    $VmsFilterSpec.Site_ids.Add($item)
                }
            }
            if ($Vcenter)
            {
                foreach ($item in $Vcenter)
                {
                    $VmsFilterSpec.Vcenter_ids.Add($item.InstanceUuid)
                }
            }
            if ($ProtectionGroup)
            {
                foreach ($pg in $ProtectionGroup)
                {
                    $VmsFilterSpec.Protection_group_ids.Add($pg.id)
                }
            }

            if ($ProtectionGroupSnapshot)
            {
                foreach ($pgs in $ProtectionGroupSnapshot)
                {
                    $VmsFilterSpec.Protection_group_snapshot_id.Add($pgs.Id)
                }
            }
        }
        else
        {
            throw $NotConnectedMsg
        }
    }
    Process
    {
        foreach ($Cfs in $CloudFileSystem)
        {  
            $Server = $CloudFileSystem.Server 
            [String] $Cursor = $Null
            do
            {
                $protectedVirtualMachines = $Server.GetProtectedVirtualMachines($Cfs, $PagingSize, $VmsFilterSpec, $Cursor)
                if (!$protectedVirtualMachines) { break }
                if (!$protectedVirtualMachines.Vms ) { break }
                $Result += $protectedVirtualMachines.Vms
                $Cursor = $protectedVirtualMachines.Cursor
            }  while ($Cursor -and $protectedVirtualMachines.Vms.Count -gt 0 )
        } 
    }
    End
    {
        return $Result
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
            
            Modified by     : VMware
            Date Modified   : 2022/08/01 
            More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
        .LINK

    #>
Function Get-VCDRRecoverySddc
{
    [OutputType([VMware.VCDRService.RecoverySddc[]])]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param(
        [Parameter( Mandatory = $false)]
        [ValidateSet([AWSRegions], ErrorMessage = "Value '{0}' is not a valid region. Try one of: {1}")]
        [String] $Region,
        [Parameter( Mandatory = $true, ParameterSetName = 'ByName', HelpMessage = 'The name of the Recovery SDDC ')]
        [String]  $Name ,
        [Parameter( Mandatory = $true, ParameterSetName = 'ById', HelpMessage = 'The identifier of the Recovery SDDC.')]
        [String]  $Id  
    )
    Begin
    { 
        if ($Script:DefaultVCDRService)
        { 
            $Server = $Script:DefaultVCDRService.SelectRegion($Region)
        }
        else
        {
            throw $NotConnectedMsg
        } 
        [VMware.VCDRService.RecoverySddc[]] $Result = @()
    }
    Process
    {
        $rSddcs = $Server.GetRecoverySddc()
        if ($rSddcs.data)
        {
            if ($name)
            {
                $cf = $rSddcs.data | Where-Object { $_.Name -eq $Name }
                if ($cf)
                {
                    $Result += $Server.GetRecoverySddcDetails($cf.id)
                }
            }
            elseif ($id)
            {
                $cf = $rSddcs.data | Where-Object { $_.Id -eq $id }
                if ($cf)
                {
                    $Result += $Server.GetRecoverySddcDetails($cf.id)
                }
            }
            else
            {
                foreach ($cf in $rSddcs.data)
                {
                    $Result += $Server.GetRecoverySddcDetails($cf.Id)
                }
            }
        }
        return $Result
    }
    End
    {
    }
} 



<#
    .SYNOPSIS
        This cmdlet convert virtual machine VCDR object to VimAutomation.
    .DESCRIPTION
         This cmdlet convert virtual machine VCDR object to VimAutomation.   
    .PARAMETER VM
        The Virtual Machines object to convert
    .EXAMPLE
        $cloudFileSystem=Get-VCDRCloudFileSystem -name "cloud-backup-1"
        $Vms=Get-VCDRProtectedVm  -CloudFileSystem $cloudFileSystem 
        $VimVms = Get-VmFromVCDR -VM $Vms -errorAction Continue
        Disconnect-VCDRService   

        Description
        -----------
        This example convert any VMs managed by the $cloudFileSystem to a standard Vim VM


    .NOTES
        FunctionName    : Get-VmFromVCDR
        Created by      : VMware
        
        Modified by     : VMware
        Date Modified   : 2023/04/10 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#>
function Get-VmFromVCDR
{
    [OutputType([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]])]
    [CmdletBinding(DefaultParameterSetName = 'ProtectionGroup')]     
    param (
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'VCDR Protected Vms', ParameterSetName = 'ProtectionGroup')][VMware.VCDRService.ProtectionGroup[]]  $ProtectionGroup,
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'VCDR Protected Vms', ParameterSetName = 'Vm')] [VMware.VCDRService.VmSummary[]] $Vm 
    ) 
    Begin
    { 
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $Result = @()
        $hash = @{}
    }
    Process
    {
        if ($global:DefaultVIServers)
        {
            if ($ProtectionGroup)
            {
                foreach ($PrGroup in $ProtectionGroup)
                {
                    foreach ($Mspec in $PrGroup.Members_specs)
                    {
                        foreach ($Folder in $Mspec.Vcenter_folder_paths)
                        {
                            $FolderParts = $Folder.split('/')
                            $Parent = Get-Datacenter($FolderParts[0])
                            for ($i = 2; $i -lt $FolderParts.Count ; $i++)
                            {
                                $Parent = Get-Folder -Name $FolderParts[$i] -Location $Parent 
                            }
                            $Result += Get-VM -Location $Parent -Server $Mspec.Vcenter_id
                        }
                        foreach ($vmname in $Mspec.Vcenter_vm_name_patterns)
                        { 
                            $Result += Get-VM -Server $Mspec.Vcenter_id -Name $vmname
                        }

                        foreach ($vmTag in $Mspec.Vcenter_tags)
                        { 
                            $Tag = Get-Tag -Server $Mspec.Vcenter_id -Name $vmTag.Tag_name -Category $vmTag.Category_name
                            $Result += Get-VM -Server $Mspec.Vcenter_id -Tag $Tag
                        }
                    }
                }
            }
            if ($Vm)
            { 
                foreach ($lvm in $Vm)
                {
                    $NotFound = $true
                    for ($i = 0; $i -lt $global:DefaultVIServers.Count ; $i++)
                    {
    
                        if ($global:DefaultVIServers[$i].InstanceUuid -eq $lvm.Id.Vcenter_id)
                        {
                            $hash[$i] += @($lvm.Id.Id)
                            $NotFound = $false
                            break 
                        } 
                    }
                    if ($NotFound -and $ErrorActionPreference -ne 'Continue')
                    {
                        throw "Please connect vCenter id:$($lvm.Id.Vcenter_id) using Connect-VIServer"
                    }
                }  
            }
        }
        else
        {
            throw 'Please connect to vCenter using Connect-VIServer'
        }
    }
    End
    { 
        if ($Vm)
        {
            for ($i = 0; $i -lt $global:DefaultVIServers.Count ; $i++)
            { 
                $Result += Get-VM -Server $global:DefaultVIServers[$i] -Id $hash[$i]
            }  
        }
        return $Result 
    }
} 




<#
    .SYNOPSIS
        This cmdlet check if a virtual machine has the HFS filter(LWD)
    .DESCRIPTION
              This cmdlet check if a virtual machine has the HFS filter(LWD).  
    .PARAMETER VM
        The Virtual Machines object to check
    .PARAMETER CloudFileSystem
        Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system for which you want to get a list of HFS
    .EXAMPLE
        $cloudFileSystem=Get-VCDRCloudFileSystem -name "cloud-backup-1"
        $Vm=Get-VM -name "test"
        Get-HFSFilter -VM $VM

        Description
        -----------
        This example return any HFS filter applied to the VM  

    .NOTES
        FunctionName    : Get-HFSFilter
        Created by      : VMware
        
        Modified by     : VMware
        Date Modified   : 2023/04/10 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#> 
function Get-HFSFilter
{
    [OutputType([HFSFilter[]] )]
    [CmdletBinding()]
    param ( [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'VM')] 
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM,
        [Parameter( Mandatory = $false, HelpMessage = 'Cloud FileSystem')]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem = @()
    )
    Begin
    { 
        [HFSFilter[]] $Result = @()
    }
    Process
    {
        foreach ( $VimVms in $(Get-VM -Name $VM))
        {
            foreach ($device in $VimVms.ExtensionData.COnfig.hardware.device)
            {
                if ($device -is [VMware.Vim.VirtualDisk])
                { 
                    foreach ($Filter in $device.IndependentFilters)
                    {
                        $Value = $Filter.FilterCapabilities.foreach{ ($_.key -eq 'vendorId')?$_.value:'' } 
                        if ($Value)
                        {
                            $Found = (!$CloudFileSystem)
                            foreach ($Cl in $CloudFileSystem)
                            {
                                if ($Value[0].contains($Cl.Id))
                                {
                                    $Found = $true
                                    break
                                }
                            }
                            if ($Found)
                            {
                                $Result += [HFSFilter]::new( $Value[0], $device.Backing.Uuid, $device.Backing.FileName)
                            } 
                        }
                        break
                    }
                    
                } 
            }
        }
    } 
    End
    { 
        return $Result 
    } 
}


<#
    .SYNOPSIS
        This cmdlet removethe HFS filter from a virtual machine 
    .DESCRIPTION
                This cmdlet removethe HFS filter from a virtual machine.
    .PARAMETER VM
        The Virtual Machines object to be reconfigured
    .PARAMETER CloudFileSystem
        Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system for which you want to get a list of HFS
    .EXAMPLE
        $cloudFileSystem=Get-VCDRCloudFileSystem -name "cloud-backup-1"
        $Vm=Get-VM -name "test"
        Remove-HFSFilter -VM $VM

        Description
        -----------
        This example remove any HFS filter applied to the VM  

    .NOTES
        FunctionName    : Remove-HFSFilter
        Created by      : VMware
        
        Modified by     : VMware
        Date Modified   : 2023/04/10 
        More info       : https://github.com/vmware/vmware-powercli-for-vmware-cloud-disaster-recovery
    .LINK

#> 

function Remove-HFSFilter
{
    [OutputType([System.Void])]
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param ( [Parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'VM')] 
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM,
        [Parameter( Mandatory = $false, HelpMessage = 'Cloud FileSystem')]
        [VMware.VCDRService.CloudFileSystem[]]  $CloudFileSystem = @()
    )
    Begin
    {
       
    }
    Process
    { 
        foreach ( $VimVms in $(Get-VM -Name $VM))
        { 
            [VMware.Vim.VirtualDeviceConfigSpec[]] $virtualDeviceSpecs = @()
            foreach ($device in $VimVms.ExtensionData.COnfig.hardware.device)
            {
                if ($device -is [VMware.Vim.VirtualDisk])
                {
                    #$device || Format-Table -RepeatHeader
                    foreach ($Filter in $device.IndependentFilters)
                    {
                        $Value = $Filter.FilterCapabilities.foreach{ ($_.key -eq 'vendorId')?$_.value:'' } 
                        if ($Value)
                        {
                            $Found = (!$CloudFileSystem)
                            foreach ($Cl in $CloudFileSystem)
                            {
                                if ($Value[0].contains($Cl.Id))
                                {
                                    $Found = $true
                                    break
                                }
                            }
                            if ($Found)
                            {  
                                $deviceSpec = New-Object VMware.Vim.VirtualDeviceConfigSpec
                                $deviceSpec.Operation = [VMware.Vim.VirtualDeviceConfigSpecOperation]::edit
                                $deviceSpec.Device = $device
                                $deviceSpec. FilterSpec = [VMware.Vim.VirtualMachineEmptyIndependentFilterSpec]::new()  
                                $virtualDeviceSpecs += $deviceSpec
                            }
                            break
                        }
                    
                    } 
                }
            } 
            if ($virtualDeviceSpecs -and $PSCmdlet.ShouldProcess($VimVms))
            {
                $vmConfigSpec = [VMware.Vim.VirtualMachineConfigSpec]::new()
                $vmConfigSpec.DeviceChange = $virtualDeviceSpecs
                $vimVms.extensionData.ReconfigVM($vmConfigSpec)  
            }
        }
    }
    End
    { 
         
    }
}

 
Set-Alias -Name Connect-VCDRServer -Value Connect-VCDRService
Set-Alias -Name Disconnect-VCDRServer -Value Disconnect-VCDRService 
Export-ModuleMember -Function Connect-VCDRService -Alias Connect-VCDRServer 
Export-ModuleMember -Function Disconnect-VCDRService -Alias Disconnect-VCDRServer
Export-ModuleMember -Function Get-VCDRInstance 
Export-ModuleMember -Function Get-DefaultVCDRInstance
Export-ModuleMember -Function Set-DefaultVCDRInstance
Export-ModuleMember -Function Get-VCDRCloudFileSystem
Export-ModuleMember -Function Get-VCDRProtectedSite
Export-ModuleMember -Function Get-VCDRProtectionGroup
Export-ModuleMember -Function Get-VCDRSnapshot
Export-ModuleMember -Function Get-VCDRProtectedVm
Export-ModuleMember -Function Get-VCDRRecoverySddc
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
Export-ModuleMember -Function Get-VmFromVCDR
Export-ModuleMember -Function Remove-HFSFilter
Export-ModuleMember -Function Get-HFSFilter