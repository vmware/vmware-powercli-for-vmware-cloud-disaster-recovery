Connect-VCDRService -Token $Token
$cloudFileSystems = Get-VCDRCloudFileSystem 
$ProtectionGroups = Get-VCDRProtectionGroup -CloudFileSystem $cloudFileSystems
$VMs = Get-VmFromVCDR -ProtectionGroup $ProtectionGroups
Remove-HFSFilter -VM $VMs



Connect-VCDRService -Token $Token 
Get-VCDRCloudFileSystem | Get-VCDRProtectionGroup | Get-VmFromVCDR | Remove-HFSFilter 