 #This is a sample OS Attack Lab
# Get-LabAvailableOperatingSystem

New-LabDefinition -Name SampleAttackLab -DefaultVirtualizationEngine HyperV

#New-LabDefinition -Name GettingStarted3 -DefaultVirtualizationEngine HyperV

# did we need this?
#Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1



# Root Domain
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$DisableWindowsDefender = Get-LabPostInstallationActivity -ScriptFileName 'DisableWindowsDefender.ps1' -DependencyFolder $labSources\PostInstallationActivities\DisableWindowsDefender


Add-LabVirtualNetworkDefinition -Name SampleAttackLab
#Add-LabVirtualNetworkDefinition -Name 'Default Switch'# -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'SampleAttackLab'
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp

Add-LabMachineDefinition -Name Router1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -Roles Routing -NetworkAdapter $netAdapter

Add-LabMachineDefinition -Name Contoso-DC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -Roles RootDC -ToolsPath $labSources\Tools -PostInstallationActivity $postInstallActivity -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-DC2 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -Roles ADDS -ToolsPath $labSources\Tools -Network SampleAttackLab

Add-LabMachineDefinition -Name Contoso-CA1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -Roles CaRoot -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-CA2 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -DomainName contoso.com -Roles CA -Network SampleAttackLab
Add-LabMachineDefinition -Name Contoso-SVR1 -Memory 1GB -OperatingSystem 'Windows Server 2008 R2 Standard (Full Installation)' -Roles WebServer -DomainName contoso.com -Network SampleAttackLab
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
#>

# Testing with new DCPull stuff
#DSC Pull Server
$role = Get-LabMachineRoleDefinition -Role DSCPullServer -Properties @{ DatabaseEngine = 'mdb' }
Add-LabMachineDefinition -Name Contoso-DSC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter Evaluation (Desktop Experience)' -Roles $role -DomainName contoso.com -Network SampleAttackLab



# Router may not be needed - depending on your situation
Enable-LabCertificateAutoenrollment -Computer -User -CodeSigning
Install-Lab

Show-LabDeploymentSummary -Detailed
