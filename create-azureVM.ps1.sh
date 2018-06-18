# power shell script by "badri"
Write-Host ""
Write-Warning "##################################################"
Write-Host "Creating AZURE virtual machine (ubuntu - Linux) "
Write-Host ""
Write-Host "the following configuration will not check for existance at AZURE cloud make sure none of them already exist !!"
Write-Host ""
Write-Host "you can give existing ResourceGroupName"
Write-Host ""
Write-Warning "###################################################"
Write-Host ""

# Variables for common values
$resourceGroup = Read-Host -Prompt 'Enter resourceGroup Name - '
$location = Read-Host -Prompt 'Enter location ex: Central US, - '
$vmName = Read-Host -Prompt 'Enter virtual machine Name - '
$MYvNET = Read-Host -Prompt 'Enter virtual network name - '
$mySubnet = Read-Host -Prompt 'Enter subnet name - '
$myNetworkSecurityGroup = Read-Host -Prompt 'Enter network security group name - '


Write-Host "Definer user name and blank password..."
# Definer user name and blank password
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

Write-Host "Creating a resource group..."
# Create a resource group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

Write-Host "creating subnet ...."
# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $mySubnet -AddressPrefix 192.168.1.0/24

Write-Host "creating virtual network ..."
# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name $MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

Write-Host "Creating a public IP address and specify a DNS name ..."
# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

Write-Host "Creating an inbound network security group rule for port 22 ..."
# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 22 -Access Allow

Write-Host "Creating a network security group ..."
# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name $myNetworkSecurityGroup -SecurityRules $nsgRuleSSH

Write-Host "Creating a virtual network card and associate with public IP address and NSG ..."
# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -Name myNic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

Write-Host "Creating a virtual machine configuration .."
# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_B1s | `
Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred -DisablePasswordAuthentication | `
Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id

Write-Host ""
Write-Host ""
# creating .ssh using ssh-keygen if does not exist !
$sshpath = "$env:USERPROFILE\.ssh\id_rsa.pub"
if([System.IO.File]::Exists($sshpath)){
        Write-Warning "$sshpath already exist!"
}
else {
        Write-Host "creating .ssh using ssh-keygen in $env:USERPROFILE "
        mkdir ~/.ssh
        cd ~/.ssh
        ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N '""'
}

Write-Host ""
Write-Host "Configuring SSH Keys for passwordless login to linux VM ..."
# Configure SSH Keys
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"

Write-Host ""
Write-Host "Creating a virtual machine .."
# Create a virtual machine
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig