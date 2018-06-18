
# Create and Add an empty data disk to a virtual machine


$resourceGroup = Read-Host -Prompt 'Enter resourceGroup Name - '
$location = Read-Host -Prompt 'Enter location ex: Central US, - '
$vmName = Read-Host -Prompt 'Enter virtual machine Name - '

$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $resourceGroup 

if ($?){

Write-Host ""
Write-Warning "####################################"
Write-Host ""
Write-Host "creating Storage Disk to attach to VM ...."
Write-Host ""
Write-Warning "###################################"
Write-Host ""

$storageType = 'Standard_LRS'
$datadisk1 = Read-Host -Prompt 'Enter disk Name - '
$dataDiskName = $vmName + '_' + $datadisk1
$diskSizeGB = Read-Host -Prompt 'Enter disk size in GB - '
$OStype = 'Linux'

Write-Host "Creating disk configuration ..."
$diskConfig = New-AzureRmDiskConfig -SkuName $storageType -Location $location -CreateOption Empty -DiskSizeGB $diskSizeGB -OsType $OStype 
Write-Host "Creating Storage disk $dataDiskName ..."
$dataDisk1 = New-AzureRmDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $resourceGroup

Write-Host "adding $dataDiskName to $vmName ..."
$vm = Add-AzureRmVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 0

Write-Host "updating VM ..."
Update-AzureRmVM -VM $vm -ResourceGroupName $resourceGroup
if ($?){
Write-Host ""
Write-Host "check AZURE console and ssh using ssh azureuser@<VM public IP> , do lsblk"
Write-Host "you can remove resourceGroup using Remove-AzureRmResourceGroup -Name <resourceGroup NAME>"
}else {
	Write-Host ""
	Write-Warning "something wrong with attachment !!"
}
} else {
	Write-Host ""
	Write-Warning "Something wrong with VM or VM does not exist !"
	Write-Host ""
}