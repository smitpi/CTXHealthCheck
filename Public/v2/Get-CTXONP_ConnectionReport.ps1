
<#PSScriptInfo

.VERSION 1.0.3

.GUID ccc3348a-02f0-4e82-91bf-d65549ca3533

.AUTHOR Pierre Smit

.COMPANYNAME iOCO Tech

.COPYRIGHT

.TAGS Citrix PowerShell

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Created [20/04/2021_10:46] Initital Script Creating
Updated [22/04/2021_11:42] Script Fle Info was updated
Updated [05/05/2021_00:03] added monitor data
Updated [05/05/2021_14:33] 'Update Manifest'

.PRIVATEDATA

#> 

#Requires -Module ImportExcel
#Requires -Module PSWriteHTML
#Requires -Module PSWriteColor



<# 
.DESCRIPTION 
Report on connections in the last x hours

#> 

Param()


Function Get-CTXONP_ConnectionReport {
	PARAM(
		[Parameter(Mandatory = $false,ParameterSetName='Got odata')]
		[pscustomobject]$MonitorData = $null,
		[Parameter(Mandatory = $false, Position = 4,ParameterSetName='Fetch odata')]
		[ValidateNotNullOrEmpty()]
		[string]$DDC,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory = $false, Position = 5,ParameterSetName='Fetch odata')]
		[int]$hours = 24,
		[Parameter(Mandatory = $false, Position = 6)]
		[ValidateSet('Excel', 'HTML')]
		[string]$Export = 'Host',
		[Parameter(Mandatory = $false, Position = 7)]
		[ValidateScript( { (Test-Path $_) })]
		[string]$ReportPath = $env:temp
	)




    if ($Null -eq $MonitorData) { $mondata =Get-CTXONP_MonitorData -DDC $DDC  -hours $hours }
    else {$mondata = $MonitorData }

	$data = @()
	foreach ($connection in $mondata.Connections) {
		try {
			$OneSession = $mondata.session | Where-Object { $_.SessionKey -eq $connection.SessionKey }
			$user = $mondata.users | Where-Object { $_.id -like $OneSession.UserId }
			$mashine = $mondata.machines | Where-Object { $_.id -like $OneSession.MachineId }
			try {
				$avgrtt = 0
				$mondata.SessionMetrics | Where-Object { $_.Sessionid -like $OneSession.SessionKey } | ForEach-Object { $avgrtt = $avgrtt + $_.IcaRttMS }
				$avgrtt = $avgrtt / ($mondata.SessionMetrics | Where-Object { $_.Sessionid -like $OneSession.SessionKey }).count
			} catch { Write-Warning "Not enough RTT data - $_.Exception.Message" }
		} catch { Write-Warning "Error processing - $_.Exception.Message" }
		$data += [PSCustomObject]@{
			Id                       = $connection.id
			FullName                 = $user.FullName
			Upn                      = $user.upn
			ConnectionState          = $ConnectionState.($OneSession.ConnectionState)
			DnsName                  = $mashine.DnsName
			IPAddress                = $mashine.IPAddress
			IsInMaintenanceMode      = $mashine.IsInMaintenanceMode
			CurrentRegistrationState = $RegistrationState.($mashine.CurrentRegistrationState)
			OSType                   = $mashine.OSType
			ClientName               = $connection.ClientName
			ClientVersion            = $connection.ClientVersion
			ClientAddress            = $connection.ClientAddress
			ClientPlatform           = $connection.ClientPlatform
			IsReconnect              = $connection.IsReconnect
			IsSecureIca              = $connection.IsSecureIca
			Protocol                 = $connection.Protocol
			EstablishmentDate        = $connection.EstablishmentDate
			LogOnStartDate           = $connection.LogOnStartDate
			LogOnEndDate             = $connection.LogOnEndDate
			AuthenticationDuration   = $connection.AuthenticationDuration
			LogOnDuration            = $OneSession.LogOnDuration
			DisconnectDate           = $connection.DisconnectDate
			EndDate                  = $OneSession.EndDate
			ExitCode                 = $SessionFailureCode.($OneSession.ExitCode)
			FailureDate              = $OneSession.FailureDate
			AVG_ICA_RTT              = [math]::Round($avgrtt)
		}
	}

	if ($Export -eq 'Excel') { $data | Export-Excel -Path ($ReportPath + '\Session_Audit-' + (Get-Date -Format yyyy.MM.dd-HH.mm) + '.xlsx') -AutoSize -AutoFilter -Show } 
	if ($Export -eq 'HTML') { $data | Out-GridHtml -DisablePaging -Title 'Citrix Sessions' -HideFooter -SearchHighlight -FixedHeader }
	if ($Export -eq 'Host') { $data }

} #end Function
