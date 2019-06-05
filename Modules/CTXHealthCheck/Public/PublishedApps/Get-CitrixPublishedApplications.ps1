
<#PSScriptInfo

.VERSION 1.0.1

.GUID 07f17625-4521-42d4-91a3-d02507d2e7b7

.AUTHOR Pierre Smit

.COMPANYNAME HTPCZA

.COPYRIGHT

.TAGS Citrix

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Date Created - 22/05/2019_19:17
Date Updated - 24/05/2019_19:25

.PRIVATEDATA

#>

<#

.DESCRIPTION
  Citrix XenDesktop HTML Health Check Report

#>

Param()



Function Get-CitrixPublishedApplications {
	PARAM(
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[string]$AdminServer,
		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$RemoteCredentials,
		[Parameter(Mandatory = $false, Position = 2)]
		[switch]$CSVExport = $false,
		[Parameter(Mandatory = $false, Position = 3)]
		[switch]$RunAsPSRemote = $false)

Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Begining] All Config"
Function GetAllConfig {
	param($AdminServer, $VerbosePreference)

Add-PSSnapin citrix*
Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Begining] All Mashine Catalogs"
$CTXMashineCatalog = @()
$MashineCatalogs = Get-BrokerCatalog -AdminAddress $AdminServer
foreach ($MashineCatalog in $MashineCatalogs)
    {
    $MasterImage = Get-ProvScheme -AdminAddress $AdminServer | Where-Object -Property IdentityPoolName -Like $MashineCatalog.Name
    $split = ($MasterImage.MasterImageVM).Split("\")
    $CatObject = New-Object PSObject -Property @{
		MashineCatalogName       = $MashineCatalog.name
		AllocationType           = $MashineCatalog.AllocationType
        Description              = $MashineCatalog.Description
        IsRemotePC               = $MashineCatalog.IsRemotePC
        MachinesArePhysical      = $MashineCatalog.MachinesArePhysical
        MinimumFunctionalLevel   = $MashineCatalog.MinimumFunctionalLevel
        PersistUserChanges       = $MashineCatalog.PersistUserChanges
        ProvisioningType         = $MashineCatalog.ProvisioningType
        SessionSupport           = $MashineCatalog.SessionSupport
        Uid                      = $MashineCatalog.Uid
        UnassignedCount          = $MashineCatalog.UnassignedCount
        UsedCount                = $MashineCatalog.UsedCount

CleanOnBoot
MasterImageVM
MasterImageSnapshot
MasterImageVMDate
UseFullDiskCloneProvisioning
UseWriteBackCache
    }


    }








Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Begining] All Delivery Groups"
$BrokerDesktopGroup = Get-BrokerDesktopGroup -AdminAddress $AdminServer
$CTXDeliveryGroup = @()
foreach ($DesktopGroup in $BrokerDesktopGroup) {
Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Delivery Group: $($DesktopGroup.name.ToString())"
	$BrokerAccess = @()
	$BrokerGroups = @()
	$BrokerAccess = Get-BrokerAccessPolicyRule -DesktopGroupUid $DesktopGroup.Uid -AdminAddress $AdminServer -AllowedConnections ViaAG | ForEach-Object { $_.IncludedUsers | Where-Object { $_.upn -notlike "" } } | select UPN
	$BrokerGroups = Get-BrokerAccessPolicyRule -DesktopGroupUid $DesktopGroup.Uid -AdminAddress $AdminServer -AllowedConnections ViaAG | ForEach-Object { $_.IncludedUsers | Where-Object { $_.upn -Like "" } } | select Fullname
    if ([bool]$BrokerAccess.UPN) {$UsersCSV = [String]::Join(';', $BrokerAccess.UPN)}
    else{$UsersCSV = ''}
    if ([bool]$BrokerGroups.FullName) {$GroupsCSV = [String]::Join(';', $BrokerGroups.FullName)}
    else{$GroupsCSV = ''}    
    $CusObject = New-Object PSObject -Property @{
		DesktopGroupName       = $DesktopGroup.name
		Uid                    = $DesktopGroup.uid
		DeliveryType           = $DesktopGroup.DeliveryType
		DesktopKind            = $DesktopGroup.DesktopKind
        Description            = $DesktopGroup.Description
		DesktopsDisconnected   = $DesktopGroup.DesktopsDisconnected
		DesktopsFaulted        = $DesktopGroup.DesktopsFaulted
		DesktopsInUse          = $DesktopGroup.DesktopsInUse
		DesktopsUnregistered   = $DesktopGroup.DesktopsUnregistered
		Enabled                = $DesktopGroup.Enabled
		IconUid                = $DesktopGroup.IconUid
		InMaintenanceMode      = $DesktopGroup.InMaintenanceMode
		SessionSupport         = $DesktopGroup.SessionSupport
		TotalApplicationGroups = $DesktopGroup.TotalApplicationGroups
		TotalApplications      = $DesktopGroup.TotalApplications
		TotalDesktops          = $DesktopGroup.TotalDesktops
        Tags                   = $DesktopGroup.Tags
		IncludedUser           = @($BrokerAccess.UPN)
		IncludeADGroups        = @($BrokerGroups.FullName)
		IncludedUserCSV        = $UsersCSV
		IncludeADGroupsCSV     = $GroupsCSV
		} 
		$CTXDeliveryGroup += $CusObject
	}
Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Begining] All Application config"
$HostedApps = @()
foreach ($DeskG in ($CTXDeliveryGroup | where { $_.DeliveryType -like 'DesktopsAndApps' })) {
	Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Delivery Group: $($DeskG.DesktopGroupName.ToString())"
	$PublishedApps = Get-BrokerApplication -AssociatedDesktopGroupUid $DeskG.Uid -AdminAddress $AdminServer
	foreach ($PublishedApp in $PublishedApps) {
		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Published Application: $($DeskG.DesktopGroupName.ToString()) - $($PublishedApp.PublishedName.ToString())"
		$PublishedAppGroup = @()
		$PublishedAppUser = @()
		foreach ($AppAssociatedUser in $PublishedApp.AssociatedUserFullNames) {
			try {
				$group = $null
				$group = Get-ADGroup $AppAssociatedUser
				if ($group -ne $null) { $PublishedAppGroup += $group.SamAccountName }
			}
			catch { }
		}
		foreach ($AppAssociatedUser2 in $PublishedApp.AssociatedUserUPNs) {
			try {
				$PublishedAppUser += $AppAssociatedUser2
			}
			catch { }
		}
        $PublishedAppUserCSV = [String]::Join(';', $PublishedAppUser)
        $PublishedAppGroupCSV = [String]::Join(';', $PublishedAppGroup)
		$CusObject = New-Object PSObject -Property @{
			DesktopGroupName         = $DeskG.DesktopGroupName
			DesktopGroupUid          = $DeskG.Uid
			DesktopGroupUsers        = $DeskG.IncludedUser
			DesktopGroupADGroups     = $DeskG.IncludeADGroups
            DesktopGroupUsersCSV     = $DeskG.IncludedUserCSV
            DesktopGroupADGroupsCSV  = $DeskG.IncludeADGroupsCSV
            ApplicationName          = $PublishedApp.ApplicationName
            ApplicationType          = $PublishedApp.ApplicationType
            AdminFolderName          = $PublishedApp.AdminFolderName
            ClientFolder             = $PublishedApp.ClientFolder
            Description              = $PublishedApp.Description
            Enabled                  = $PublishedApp.Enabled
            CommandLineExecutable    = $PublishedApp.CommandLineExecutable
            CommandLineArguments     = $PublishedApp.CommandLineArguments
            WorkingDirectory         = $PublishedApp.WorkingDirectory
            Tags                     = $PublishedApp.Tags
			PublishedName            = $PublishedApp.PublishedName
			PublishedAppName         = $PublishedApp.Name                    
			PublishedAppGroup        = $PublishedAppGroup
			PublishedAppUser         = $PublishedAppUser
			PublishedAppGroupCSV     = $PublishedAppGroupCSV
			PublishedAppUserCSV      = $PublishedAppUserCSV
		} 
$HostedApps += $CusObject
		}
	}

Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Ending] Published Applications"
if ($CSVExport) {
    $CTXDeliveryGroup = $CTXDeliveryGroup | select DesktopGroupName,Uid,DeliveryType,DesktopKind,Description,DesktopsDisconnected,DesktopsFaulted,DesktopsInUse,DesktopsUnregistered,Enabled,IconUid,InMaintenanceMode,SessionSupport,TotalApplicationGroups,TotalApplications,TotalDesktops,Tags,IncludedUserCSV,IncludeADGroupsCSV
    $HostedApps = $HostedApps | select  DesktopGroupName,DesktopGroupUid,DesktopGroupUsersCSV,DesktopGroupADGroupsCSV,ApplicationName,ApplicationType,AdminFolderName,ClientFolder,Description,Enabled,CommandLineExecutable,CommandLineArguments,WorkingDirectory,Tags,PublishedName,PublishedAppName,PublishedAppGroup,PublishedAppUser,PublishedAppGroupCSV,PublishedAppUserCSV
    }
else {
    $CTXDeliveryGroup = $CTXDeliveryGroup | select DesktopGroupName,Uid,DeliveryType,DesktopKind,Description,DesktopsDisconnected,DesktopsFaulted,DesktopsInUse,DesktopsUnregistered,Enabled,IconUid,InMaintenanceMode,SessionSupport,TotalApplicationGroups,TotalApplications,TotalDesktops,Tags,IncludedUser,IncludeADGroups
    $HostedApps = $HostedApps | select  DesktopGroupName,DesktopGroupUid,DesktopGroupUsers,DesktopGroupADGroups,ApplicationName,ApplicationType,AdminFolderName,ClientFolder,Description,Enabled,CommandLineExecutable,CommandLineArguments,WorkingDirectory,Tags,PublishedName,PublishedAppName,PublishedAppGroup,PublishedAppUser
    }

$CusObject = New-Object PSObject -Property @{
	DateCollected  = (Get-Date -Format dd-MM-yyyy_HH:mm).ToString()
	DeliveryGroups = $CTXDeliveryGroup
	PublishedApps  = $HostedApps
    }
$CusObject
}

$AppDetail = @()
if ($RunAsPSRemote -eq $true) { $AppDetail = Invoke-Command -ComputerName $AdminServer -ScriptBlock ${Function:GetAllConfig} -ArgumentList  @($AdminServer, $VerbosePreference) -Credential $RemoteCredentials }
else { $AppDetail = GetAllConfig -AdminServer $AdminServer -VerbosePreference $VerbosePreference}
Write-Verbose "$((get-date -Format HH:mm:ss).ToString()) [Ending] All Details"
$AppDetail | select DateCollected, DeliveryGroups, PublishedApps

} #end Function
