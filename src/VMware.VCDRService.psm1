if (!$global:DefaultVCDRServer) {
    [System.Collections.ArrayList]$global:DefaultVCDRServer = @()
}
update-TypeData -TypeName "VMware.VCDRService.ProtectionGroup" -DefaultDisplayPropertySet Name, Health, used_gib
update-TypeData -TypeName "VMware.VCDRService.ProtectionGroupSnapshot" -DefaultDisplayPropertySet   Name , vm_count, failed_vm_snap_count, total_used_data_gib
update-TypeData -TypeName "VMware.VCDRService.CloudFileSystem" -DefaultDisplayPropertySet   Name , Capacity_gib, Used_gib
update-TypeData -TypeName "VMware.VCDRService.ProtectedSite" -DefaultDisplayPropertySet   Name , Type
update-TypeData -TypeName "VMware.VCDRService.VCDRServer" -DefaultDisplayPropertySet Server , Version
update-TypeData -TypeName "VMware.VCDRService.VmSummary" -DefaultDisplayPropertySet Name, Size, Vcdr_vm_id
update-TypeData -TypeName "VMware.VCDRService.RecoverySddc"  -DefaultDisplayPropertySet Name, Region, Availability_zones
$PagingSize = 100

Function CheckConnection {
    Param (
        [Parameter( Mandatory = $false, HelpMessage = " Specifies the VCDR Server systems you want to check")]
        [VMware.VCDRService.VCDRServer] $Server
    )

    if ($Server) {
        return $Server
    }
    if ($global:DefaultVCDRServer -and $global:DefaultVCDRServer.Count -gt 0) {
        return $global:DefaultVCDRServer[0]
    }
    throw "No Server connected"
}
<#
        .SYNOPSIS
            This cmdlet establishes a connection to a VCDR Server system.
        .DESCRIPTION
             This cmdlet establishes a connection to a VCDR Server system. The cmdlet starts a new session or re-establishes
		a previous session with a VCDR Server system using the specified parameters.
        .PARAMETER Name
           The name of the Cloud File System
        .PARAMETER Id
            The identifier of the cloud file system.
        .EXAMPLE
			$token="<my VMC TOKEN>"
			$server = "vcdr-xxx-yyy-zzz-kkk.app.vcdr.vmware.com"

			$VCDR=Connect-VCDRServer  -server $server -token $token

            Description
            -----------
            This example connect to a VCDR Server system  using a VMC token


        .NOTES
            FunctionName    : Connect-VCDRServer
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
Function Connect-VCDRServer {
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory = $true, HelpMessage = "User Token")]
        [String]  $token,
        [Parameter( Mandatory = $true, HelpMessage = "VCDR Server FQDN")]
        [String]  $server
    )
    Begin {
        [VMware.VCDRService.VMCEnviroment] $VMCEnviroment = [VMware.VCDRService.VMCEnviroment]::Production
        if ($server -Match ".staging.app.vcdr.vmware.com") {
            $VMCEnviroment = [VMware.VCDRService.VMCEnviroment]::Stage
        }

    }
    Process {
        [VMware.VCDRService.VCDRServer] $client = New-Object VMware.VCDRService.VCDRServer($token, $VMCEnviroment)
        $client.server = $server
        for ($i = 0; $i -lt $global:DefaultVCDRServer.Count ; $i++) {
            if ($global:DefaultVCDRServer[$i].server -eq $server) {
                $global:DefaultVCDRServer[$i] = $client
                return $client
            }
        }
        $global:DefaultVCDRServer += $client
        return $client
    }
    End {
    }
}


<#
        .SYNOPSIS
            This cmdlet closes the connection to a VCDR Server system.
        .DESCRIPTION
              This cmdlet closes the connection to a VCDR Server system. You can have multiple connections to a
    server. In order to disconnect from a server, you must close all active connections to it. By default,
    Disconnect-VIServer closes only the last connection to the specified server. To close all active connections to a
    server, use the Force parameter or run the cmdlet for each connection. When a server is disconnected, it is
    removed from the default servers list. For more information about default servers, see the description of
    Connect-VCDRServer.
        .PARAMETER Server
           Specifies the VCDR Server systems you want to disconnect from.

        .EXAMPLE
			$token="<my VMC TOKEN>"
            $server = "vcdr-xxx-yyy-zzz-kkk.app.vcdr.vmware.com"
            $VCDR=Connect-VCDRServer  -server $server -token $token

			Disconnect-VCDRServer  -server $VCDR

            Description
            -----------
            This example connect to a VCDR Server system  using a VMC token.Then disconnects from the specified server.


        .NOTES
            FunctionName    : Disconnect-VCDRServer
            Created by      : VMware
            Date Coded      : 2022/02/20
            Modified by     : VMware
            Date Modified   : 2022/02/20 16:12:10
            More info       : https://vmware.github.com/
        .LINK

    #>
Function Disconnect-VCDRServer {
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory = $false, HelpMessage = "Specifies the VCDR Server systems you want to disconnect from")]
        [VMware.VCDRService.VCDRServer]  $server

    )
    Begin {
        if ($global:DefaultVCDRServer.Count -eq 0) {
            throw "Cmdlets is currently not connected to a server. To create a new connection use Connect-VCDRServer."
        }

        if ($server) {
            for ($i = 0; $i -lt $global:DefaultVCDRServer.Count ; $i++) {
                if ($global:DefaultVCDRServer[$i].server -eq $server.server) {
                    $global:DefaultVCDRServer[$i].Dispose()
                    $global:DefaultVCDRServer.RemoveAt($i)
                    return
                }

            }
            throw "Cmdlets is currently not connected to a" + $server.server
        }
        else {
            if ($global:DefaultVCDRServer.Count -gt 0) {
                $global:DefaultVCDRServer[0].Dispose()
                $global:DefaultVCDRServer.RemoveAt(0)
            }
        }


    }
    Process {
    }
    End {
    }
}


<#
        .SYNOPSIS
            List of cloud file systems
        .DESCRIPTION
            Get a list of any deployed cloud file systems in your VMware Cloud DR organization with details.
        .PARAMETER Server
            Specifies the VCDR Server systems on which you want to run the cmdlet. If no value is provided or `$null value is passed to this parameter, the command runs on the default servers. For more information about default servers, see the description of Connect-VCDRServer.
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
        [Parameter( Mandatory = $false, HelpMessage = "Specifies the VCDR Server systems on which you want to run the cmdlet. If no value is provided or `$null value is passed to this parameter, the command runs on the default servers. For more information about default servers, see the description of Connect-VCDRServer.")]
        [VMware.VCDRService.VCDRServer] $Server,
        [Parameter( Mandatory = $false, ParameterSetName = "ByName", HelpMessage = "The name of the Cloud File System ")]
        [String]  $Name ,
        [Parameter( Mandatory = $false, ParameterSetName = "ById", HelpMessage = "The identifier of the cloud file system.")]
        [String]  $Id
    )
    Begin {
        $Server = CheckConnection -Server $Server
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
        [VMware.VCDRService.CloudFileSystem]  $CloudFileSystem,
        [Parameter( Mandatory = $false, HelpMessage = "vCenter")]
        [String[]]  $Vcenter ,
        [Parameter( Mandatory = $false, HelpMessage = "Protection Group")]
        [String[]]  $ProtectionGroup,
        [Parameter( Mandatory = $false, HelpMessage = "Specifies the VCDR Server systems on which you want to run the cmdlet. If no value is provided or `$null value is passed to this parameter, the command runs on the default servers. For more information about default servers, see the description of Connect-VCDRServer.")]
        [VMware.VCDRService.VCDRServer] $Server

    )
    Begin {
        $Server = CheckConnection -Server $Server
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

    }
    Process {
        [String]   $Cursor = $Null
        $protectedSites = [VMware.VCDRService.GetProtectedSitesResponse[]]@()
        do {
            $protectedSitesResponse = $Server.GetProtectedSites($CloudFileSystem.Id, $PagingSize, $protectedSitesFilterSpec, $Cursor)
            if (! $protectedSitesResponse) {
                break
            }
            $protectedSites += $protectedSitesResponse.Protected_sites
            $Cursor = $protectedSitesResponse.Cursor
        }  while ($Cursor -and $protectedSitesResponse.Protected_sites -gt 0 )

        foreach ($ps in $protectedSites) {
            $result += $Server.GetProtectedSiteDetails($CloudFileSystem.Id, $ps.Id)
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
        [VMware.VCDRService.CloudFileSystem]  $CloudFileSystem,

        [Parameter( Mandatory = $false, HelpMessage = "vCenter ID")]
        [String[]]  $Vcenter ,
        [Parameter( Mandatory = $false, HelpMessage = "Site ID")]
        [String[]]  $Site ,
        [Parameter( Mandatory = $false, HelpMessage = "Specifies the VCDR Server systems on which you want to run the cmdlet. If no value is provided or `$null value is passed to this parameter, the command runs on the default servers. For more information about default servers, see the description of Connect-VCDRServer.")]
        [VMware.VCDRService.VCDRServer] $Server
    )
    Begin {
        $Server = CheckConnection -Server $Server
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
    }
    Process {
        $protectedGroups = [VMware.VCDRService.GetProtectionGroupsResponse[]]@()
        [String]   $Cursor = $Null
        do {
            $protectedGroupsResponse = $Server.GetProtectionGroups($CloudFileSystem.Id, $PagingSize, $protectionGroupsFilterSpec, $Cursor)
            if (!$protectedGroupsResponse.Protection_groups ) { break }
            $protectedGroups += $protectedGroupsResponse.Protection_groups
            $Cursor = $protectedGroupsResponse.Cursor
        }  while ($Cursor -and $protectedGroupsResponse.Protection_groups -gt 0 )

        foreach ($ps in $protectedGroups) {
            $result += $Server.GetProtectionGroupDetails($CloudFileSystem.Id, $ps.Id)
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
        [String ]  $SnapshotID,
        [Parameter( Mandatory = $false, HelpMessage = "Specifies the VCDR Server systems on which you want to run the cmdlet. If no value is provided or `$null value is passed to this parameter, the command runs on the default servers. For more information about default servers, see the description of Connect-VCDRServer.")]
        [VMware.VCDRService.VCDRServer] $Server
    )
    Begin {
        $Server = CheckConnection -Server $Server
        $result = [VMware.VCDRService.ProtectionGroupSnapshot[]]@()
    }
    Process {

        if ( $SnapshotID ) {
            $result += $Server.GetProtectionGroupSnapshotDetails($ProtectionGroup.CloudFileSystemId, $ProtectionGroup.Id, $SnapshotID)
        }
        else {

            foreach ($ProtectionGroup in  $ProtectionGroups) {
                [String] $Cursor = $Null
                $Snapshots = [VMware.VCDRService.GetProtectionGroupSnapshotsResponse[]]@()
                do {
                    $protectionGroupSnapshotResponse = $Server.GetProtectionGroupSnapshots($ProtectionGroup.CloudFileSystemId, $ProtectionGroup.Id, $PagingSize, $Cursor)
                    if (!$protectionGroupSnapshotResponse) { break }
                    if (!$protectionGroupSnapshotResponse.Snapshots) { break }
                    $Cursor = $protectionGroupSnapshotResponse.Cursor
                    $Snapshots += $protectionGroupSnapshotResponse.Snapshots
                }  while ($Cursor -and $protectionGroupSnapshotResponse.Snaphsots -gt 0 )
                foreach ($ps in $Snapshots) {
                    $result += $Server.GetProtectionGroupSnapshotDetails($ProtectionGroup.CloudFileSystemId, $ProtectionGroup.Id, $ps.Id)
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
        [VMware.VCDRService.CloudFileSystem]  $CloudFileSystem,

        [Parameter( Mandatory = $false, HelpMessage = "vCenter ID")]
        [String[]]  $Vcenter ,
        [Parameter( Mandatory = $false, HelpMessage = "Site ID")]
        [String[]]  $Site ,
        [Parameter( Mandatory = $false, HelpMessage = "Protection Group ID")]
        [VMware.VCDRService.ProtectionGroup[]]  $ProtectionGroup ,
        [Parameter( Mandatory = $false, HelpMessage = "Protection Group Snapshot ID")]
        [VMware.VCDRService.ProtectionGroupSnapshot[]] $ProtectionGroupSnapshot,
        [Parameter( Mandatory = $false, HelpMessage = "Specifies the VCDR Server systems on which you want to run the cmdlet. If no value is provided or `$null value is passed to this parameter, the command runs on the default servers. For more information about default servers, see the description of Connect-VCDRServer.")]
        [VMware.VCDRService.VCDRServer] $Server
    )
    Begin {


        $Server = CheckConnection -Server $Server
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

    }
    Process {
        [String] $Cursor = $Null
        do {
            $protectedVirtualMachines = $Server.GetProtectedVirtualMachines($CloudFileSystem.Id, $PagingSize, $VmsFilterSpec, $Cursor)
            if (!$protectedVirtualMachines) { break }
            if (!$protectedVirtualMachines.Vms ) { break }
            $result += $protectedVirtualMachines.Vms
            $Cursor = $protectedVirtualMachines.Cursor
        }  while ($Cursor -and $protectedVirtualMachines.Vms.Count -gt 0 )
        return $result
    }
    End {
    }
}



<#
        .SYNOPSIS
            List of Recovery SDDCs
        .DESCRIPTION
            A Recovery SDDC is a VMware Cloud (VMC) software-defined datacenter (SDDC) where protected VMs are created, configured, and powered on during VMware Cloud DR failover.
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
        [Parameter( Mandatory = $false, ParameterSetName = "ByName", HelpMessage = "The name of the Recovery SDDC ")]
        [String]  $Name ,
        [Parameter( Mandatory = $false, ParameterSetName = "ById", HelpMessage = "The identifier of the Recovery SDDC.")]
        [String]  $Id ,
        [Parameter( Mandatory = $false, HelpMessage = "Specifies the VCDR Server systems on which you want to run the cmdlet. If no value is provided or `$null value is passed to this parameter, the command runs on the default servers. For more information about default servers, see the description of Connect-VCDRServer.")]
        [VMware.VCDRService.VCDRServer] $Server
    )
    Begin {
        $Server = CheckConnection -Server $Server
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


Export-ModuleMember -Function Connect-VCDRServer
Export-ModuleMember -Function Disconnect-VCDRServer
Export-ModuleMember -Function Get-VCDRCloudFileSystem
Export-ModuleMember -Function Get-VCDRProtectedSite
Export-ModuleMember -Function Get-VCDRProtectionGroup
Export-ModuleMember -Function Get-VCDRSnapshot
Export-ModuleMember -Function Get-VCDRProtectedVm
Export-ModuleMember -Function Get-VCDRRecoverySddc
