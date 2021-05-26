
<#PSScriptInfo

.VERSION 1.0.1

.GUID c7bf330c-de8a-4741-8af7-f8858a0109d4

.AUTHOR Pierre Smit

.COMPANYNAME iOCO Tech

.COPYRIGHT

.TAGS citrix

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Created [05/05/2021_14:43] Initital Script Creating
Updated [05/05/2021_14:45] manifest file

.PRIVATEDATA

#> 

#Requires -Module ImportExcel
#Requires -Module PSWriteHTML
#Requires -Module PSWriteColor

<# 

.DESCRIPTION 
Run report to show usefull information

#> 

Param()




Function Get-CTXONP_HealthCheck {
	PARAM(
		[Parameter(Mandatory = $false, Position = 0)]
		[string]$DDC,
		[Parameter(Mandatory = $false, Position = 4)]
		[ValidateScript( { (Test-Path $_) })]
		[string]$ReportPath = $env:temp
	)
	#######################
	#region Get data
	#######################
	try {
        Add-PSSnapin citrix* -ErrorAction SilentlyContinue
		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Config Log"
		$configlog = (Get-CitrixConfigurationChange -DDC $DDC -Indays 7).Summary | Where-Object { $_.name -ne "" } | Sort-Object count -Descending | Select-Object -First 5 -Property count, name
		
		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Delivery Groups"
		$DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $DDC | Select-Object Name,DeliveryType,DesktopsAvailable,DesktopsDisconnected,DesktopsFaulted,DesktopsNeverRegistered,DesktopsUnregistered,InMaintenanceMode,IsBroken,RegisteredMachines,SessionCount

		$MonitorData = Get-CTXONP_MonitorData -DDC $DDC  -hours 24

		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Connection Report"
		$ConnectionReport = Get-CTXONP_ConnectionReport -MonitorData $MonitorData
		$connectionRTT = $ConnectionReport | Sort-Object -Property AVG_ICA_RTT -Descending -Unique | Select-Object -First 5 FullName,ClientVersion,ClientAddress,AVG_ICA_RTT
		$connectionLogon = $ConnectionReport | Sort-Object -Property LogOnDuration -Descending -Unique | Select-Object -First 5 FullName,ClientVersion,ClientAddress,LogOnDuration
    
		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Resource Utilization"
		$ResourceUtilization = Get-CTXONP_ResourceUtilization -MonitorData $MonitorData

		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Failure Report"
		$ConnectionFailureReport = Get-CTXONP_FailureReport -MonitorData $MonitorData -DDC $DDC -FailureType Connection
		$MachineFailureReport =  Get-CTXONP_FailureReport -MonitorData $MonitorData -DDC $DDC -FailureType Machine | Select-Object Name,IP,OSType,FailureStartDate,FailureEndDate,FaultState


		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Processing] Sessions"
		$sessions = Get-BrokerSession -AdminAddress $ddc
		$sessioncount = [PSCustomObject]@{
			Connected         = ($sessions | Where-Object { $_.SessionState -like 'active' }).count
			Disconnected      = ($sessions | Where-Object { $_.SessionState -like 'Disconnected' }).count
			ConnectionFailure = $ConnectionFailureReport.count
			MachineFailure    = $MachineFailureReport.count
		}

		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) Machines"
		$vdauptime =  Get-CTXONP_VDAUptime -DDC $DDC
		$machinecount = [PSCustomObject]@{
			Inmaintenance = ($vdauptime | Where-Object { $_.InMaintenanceMode -like 'true' }).count
			DesktopCount  = ($vdauptime | Where-Object { $_.OSType -like 'Windows 10' }).count
			ServerCount   = ($vdauptime | Where-Object { $_.OSType -notlike 'Windows 10' }).count
			AgentVersions = ($vdauptime | Group-Object -Property AgentVersion).count
			NeedsReboot   = ($vdauptime | Where-Object { $_.days -gt 7 }).count
		}
		#endregion
		#######################
		#region Table settings
		#######################

		$TableSettings = @{
			#Style          = 'stripe'
			Style          = 'cell-border'
			HideFooter     = $true
			OrderMulti     = $true
			TextWhenNoData = 'No Data to display here'
		}

		$SectionSettings = @{
			BackgroundColor       = 'white'
			CanCollapse           = $true
			HeaderBackGroundColor = 'white'
			HeaderTextAlignment   = 'center'
			HeaderTextColor       = 'grey'
		}

		$TableSectionSettings = @{
			BackgroundColor       = 'white'
			HeaderBackGroundColor = 'grey'
			HeaderTextAlignment   = 'center'
			HeaderTextColor       = 'white'
		}
		#endregion

		#######################
		#region Building HTML the report
		#######################
		Write-Verbose "$((Get-Date -Format HH:mm:ss).ToString()) [Proccessing] Building HTML Page"
        $SiteName = Get-BrokerSite -AdminAddress $DDC | ForEach-Object {$_.Name}
		[string]$HTMLReportname = $ReportPath + "\XD_HealthChecks-$SiteName-" + (Get-Date -Format yyyy.MM.dd-HH.mm) + '.html'

		$HeadingText = $SiteName + ' | Report | ' + (Get-Date -Format dd) + ' ' + (Get-Date -Format MMMM) + ',' + (Get-Date -Format yyyy) + ' ' + (Get-Date -Format HH:mm)

		New-HTML -TitleText "$SiteName Report" -FilePath $HTMLReportname -ShowHTML {
			New-HTMLHeading -Heading h1 -HeadingText $HeadingText -Color Black
			New-HTMLSection @SectionSettings -Content {
				New-HTMLSection -HeaderText 'Session States' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $sessioncount }
			}
			New-HTMLSection @SectionSettings -Content {
				New-HTMLSection -HeaderText 'Top 5 RTT Sessions' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $connectionRTT }
				New-HTMLSection -HeaderText 'Top 5 Logon Duration' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $connectionLogon }
			}
			New-HTMLSection @SectionSettings -Content {
				New-HTMLSection -HeaderText 'Connection Failures' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $ConnectionFailureReport }
				New-HTMLSection -HeaderText 'Machine Failures' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $MachineFailureReport }
			}
			New-HTMLSection @SectionSettings -Content {
				New-HTMLSection -HeaderText 'Config Changes' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $configlog }
				New-HTMLSection -HeaderText 'Machine Summary' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable ($machinecount.psobject.Properties | Select-Object name,value) }
			}

			New-HTMLSection @SectionSettings -Content {
				New-HTMLSection -HeaderText 'Delivery Groups' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $DeliveryGroups }
			}
			New-HTMLSection @SectionSettings -Content {
				New-HTMLSection -HeaderText 'VDI Uptimes' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $vdauptime }
			}
			New-HTMLSection @SectionSettings -Content {
				New-HTMLSection -HeaderText 'Resource Utilization' @TableSectionSettings { New-HTMLTable @TableSettings -DataTable $ResourceUtilization }
			}
		}
		#endregion
	} catch {
		Write-Error "Failed to generate report:$($_)" 
 }

} #end Function
