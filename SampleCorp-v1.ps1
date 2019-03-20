 #This is a sample OS Attack Lab
# Get-LabAvailableOperatingSystem

New-LabDefinition -Name SampleCorp -DefaultVirtualizationEngine HyperV

$VMPrefix = "DEV4"
$rootDomainName = "corpad.dev"
$domainName = "company.corpad.dev"

Add-LabDomainDefinition -Name $rootDomainName -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name $domainName -AdminUser Install -AdminPassword Somepass1


# Setup the Switches (this is for the Router)
#Add-LabVirtualNetworkDefinition -Name 'Default Switch'# -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }
#Add-LabVirtualNetworkDefinition -Name SampleCorp
#Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }


#$netAdapter = @()
#$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'SampleCorp'
#$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp


# OS Variables
$2016 = "Windows Server 2016 Datacenter"
$2016EV = "Windows Server 2016 Datacenter Evaluation (Desktop Experience)"
$2008R2 = "Windows Server 2008 R2 Standard (Full Installation)"

$default = $2016EV
# Default parameters
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= "$2016"
    'Add-LabMachineDefinition:Memory'= 2GB
}




# Root Domain Setup
Set-LabInstallationCredential -Username Install -Password Somepass1

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name "$VMPrefix-DCROOT-01" -DomainName $rootDomainName -Roles RootDC -PostInstallationActivity $postInstallActivity -Network SampleCorp -OperatingSystem $default

# Modify as Nescersary
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
# Create first DC
Add-LabMachineDefinition -Name "$VMPrefix-DCCORP-01" -DomainName $domainName -Roles FirstChildDC -PostInstallationActivity $postInstallActivity -Network SampleCorp -OperatingSystem $default


# Optional Router
#Add-LabMachineDefinition -Name Router1 -Memory 1GB -OperatingSystem $2016EV -Roles Routing -NetworkAdapter $netAdapter

<#

Add-LabMachineDefinition -Name "$Dev4-DCROOT-01" -Memory 1GB -OperatingSystem $2016 -DomainName contoso.com -Roles RootDC -ToolsPath $labSources\Tools -PostInstallationActivity $postInstallActivity -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-DC2 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -Roles ADDS -ToolsPath $labSources\Tools -Network SampleAttackLab

Add-LabMachineDefinition -Name Contoso-CA1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -Roles CaRoot -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-CA2 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -Roles CA -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-SVR1 -Memory 1GB -OperatingSystem $2008R2 -Roles WebServer -DomainName contoso.com -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-SVR2 -Memory 1GB -OperatingSystem 'Windows Server 2012 R2 Standard (Server with a GUI)'-Roles FileServer -DomainName contoso.com -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-Client1 -Memory 768MB -OperatingSystem 'Windows 7 Enterprise' -DomainName contoso.com -ToolsPath $labSources\Tools -PostInstallationActivity $DisableWindowsDefender -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-Client2 -Memory 1GB -OperatingSystem 'Windows 10 Enterprise Evaluation' -DomainName contoso.com -ToolsPath $labSources\Tools -PostInstallationActivity $DisableWindowsDefender -Network SampleAttackLab


# Add some SQL for SCCM
Add-LabIsoImageDefinition -Name SQLServer2017 -Path $labSources\ISOs\Microsoft_SQL_Server_2017_Standard_Edition.iso
$sccmRole = Get-LabPostInstallationActivity -CustomRole SCCM -Properties @{
    SccmSiteCode = "S01"
    SccmBinariesDirectory = "$labSources\SoftwarePackages\SCCM1702"
    SccmPreReqsDirectory = "$labSources\SoftwarePackages\SCCMPreReqs"
    AdkDownloadPath = "$labSources\SoftwarePackages\ADK"
    SqlServerName = 'Contoso-SQL1'
}
$sqlRole = Get-LabMachineRoleDefinition -Role SQLServer2017 -Properties @{ Collation = 'SQL_Latin1_General_CP1_CI_AS' }
Add-LabMachineDefinition -Name Contoso-SQL1 -Memory 2GB -Roles $sqlRole -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -Network SampleAttackLab -DomainName contoso.com
Add-LabMachineDefinition -Name Contoso-SCCM1 -Memory 4GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -PostInstallationActivity $sccmRole -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-Client3 -Memory 1GB -OperatingSystem 'Windows 10 Enterprise Evaluation' -DomainName contoso.com -ToolsPath $labSources\Tools -PostInstallationActivity $DisableWindowsDefender -Network SampleAttackLab

# Add some Linux for fun
#Add-LabMachineDefinition -Name Contoso-CentOS -OperatingSystem 'CentOS-7' -DomainName Contoso.com -Network SampleAttackLab -RhelPackage gnome-desktop -DnsServer1 192.168.13.3 -Memory 1GB -Gateway 192.168.13.4

# Add some ExchangeServer
<#
$r = Get-LabPostInstallationActivity -CustomRole Exchange2016 -Properties @{ OrganizationName = 'ContosoTest1' }
Add-LabMachineDefinition -Name Contoso-EX1 -Memory 6GB -PostInstallationActivity $r -Network SampleAttackLab --OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)'
Install-LabSoftwarePackage -Path $labSources\OSUpdates\windows10.0-kb3206632-x64_b2e20b7e1aa65288007de21e88cd21c3ffb05110.msu -ComputerName Lab2016EX1 -Timeout 60


# Testing with new DCPull stuff
#DSC Pull Server
$role = Get-LabMachineRoleDefinition -Role DSCPullServer -Properties @{ DatabaseEngine = 'mdb' }
Add-LabMachineDefinition -Name Contoso-DSC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -Roles $role -DomainName contoso.com -Network SampleAttackLab

#>

# Router may not be needed - depending on your situation
Enable-LabCertificateAutoenrollment -Computer -User -CodeSigning
Install-Lab

Show-LabDeploymentSummary -Detailed