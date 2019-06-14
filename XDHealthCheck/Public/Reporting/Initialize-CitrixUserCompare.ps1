
<#PSScriptInfo

.VERSION 1.0.1

.GUID 310be7d5-f671-4eaa-8011-8552cdcfc75c

.AUTHOR Pierre Smit

.COMPANYNAME

.COPYRIGHT

.TAGS Citrix

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Created [07/06/2019_04:05]
Updated [09/06/2019_09:18]

.PRIVATEDATA

#>



<#

.DESCRIPTION
Reports on user details

#>

Param()
Function Compare-ADUser {
    PARAM($Username1,$Username2)

$ValidUser1 = Get-ADUser $Username1  -Properties * | Select-Object Name,GivenName,Surname,UserPrincipalName, EmailAddress, EmployeeID, EmployeeNumber, HomeDirectory, Enabled, Created, Modified, LastLogonDate,samaccountname
$ValidUser2 = Get-ADUser $Username2  -Properties * | Select-Object Name,GivenName,Surname,UserPrincipalName, EmailAddress, EmployeeID, EmployeeNumber, HomeDirectory, Enabled, Created, Modified, LastLogonDate,samaccountname
$userDetailList1 = $ValidUser1.psobject.Properties | Select-Object -Property Name, Value
$userDetailList2 = $ValidUser2.psobject.Properties | Select-Object -Property Name, Value

$user1Headding = $ValidUser1.Name
$user2Headding = $ValidUser2.Name
$user1HeaddingMissing = $ValidUser1.Name + " Missing"
$user2HeaddingMissing = $ValidUser2.Name + " Missing"

$allusergroups1 = Get-ADUser $Username1 -Properties * | Select-Object -ExpandProperty memberof | ForEach-Object {Get-ADGroup $_} | Select-Object samaccountname
$allusergroups2 = Get-ADUser $Username2 -Properties * | Select-Object -ExpandProperty memberof | ForEach-Object {Get-ADGroup $_} | Select-Object samaccountname

$Compare = Compare-Object -ReferenceObject $allusergroups1 -DifferenceObject $allusergroups2 -Property samaccountname -IncludeEqual

$SameGroups = $Compare | Where-Object {$_.SideIndicator -eq '=='} | Select-Object samaccountname
$User1Missing = $Compare | Where-Object {$_.SideIndicator -eq '=>'} | Select-Object samaccountname
$User2Missing = $Compare | Where-Object {$_.SideIndicator -eq '<='} | Select-Object samaccountname


$User1Details = New-Object PSObject  -Property @{
        ValidUser1               = $ValidUser1
        userDetailList1          = $userDetailList1
        user1Headding            = $user1Headding
        user1HeaddingMissing     = $user1HeaddingMissing
        allusergroups1           = $allusergroups1
        User1Missing             = $User1Missing
        }
$User2Details = New-Object PSObject  -Property @{
        ValidUser2               = $ValidUser2
        userDetailList2          = $userDetailList2
        user2Headding            = $user2Headding
        user2HeaddingMissing     = $user2HeaddingMissing
        allusergroups2           = $allusergroups2
        User2Missing             = $User2Missing
        }

$Details = New-Object PSObject  -Property @{
User1Details = $User1Details
User2Details = $User2Details
SameGroups = $SameGroups
}
$Details

} #end Function

Function Initialize-CitrixUserCompare {
    PARAM(
		[Parameter(Mandatory = $false, Position = 0)]
		[ValidateScript( { (Test-Path $_) -and ((Get-Item $_).Extension -eq ".xml") })]
		[string]$XMLParameterFilePath = (Get-Item $profile).DirectoryName + "\Parameters.xml",
		[Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username1,
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username2)


Write-Verbose "$((get-date -Format HH:mm:ss).ToString()) [Proccessing] Importing Variables"

Write-Colour "Using these Variables"
[XML]$XMLParameter = Get-Content $XMLParameterFilePath
$XMLParameter.Settings.Variables.Variable | Format-Table
Write-Verbose "$((get-date -Format HH:mm:ss).ToString()) [Starting] Variable Details"

$XMLParameter.Settings.Variables.Variable | ForEach-Object {
		# Set Variables contained in XML file
		$VarValue = $_.Value
		$CreateVariable = $True # Default value to create XML content as Variable
		switch ($_.Type) {
			# Format data types for each variable
			'[string]' { $VarValue = [string]$VarValue } # Fixed-length string of Unicode characters
			'[char]' { $VarValue = [char]$VarValue } # A Unicode 16-bit character
			'[byte]' { $VarValue = [byte]$VarValue } # An 8-bit unsigned character
            '[bool]' { If ($VarValue.ToLower() -eq 'false'){$VarValue = [bool]$False} ElseIf ($VarValue.ToLower() -eq 'true'){$VarValue = [bool]$True} } # An boolean True/False value
			'[int]' { $VarValue = [int]$VarValue } # 32-bit signed integer
			'[long]' { $VarValue = [long]$VarValue } # 64-bit signed integer
			'[decimal]' { $VarValue = [decimal]$VarValue } # A 128-bit decimal value
			'[single]' { $VarValue = [single]$VarValue } # Single-precision 32-bit floating point number
			'[double]' { $VarValue = [double]$VarValue } # Double-precision 64-bit floating point number
			'[DateTime]' { $VarValue = [DateTime]$VarValue } # Date and Time
			'[Array]' { $VarValue = [Array]$VarValue.Split(',') } # Array
		}
		If ($CreateVariable) { New-Variable -Name $_.Name -Value $VarValue -Scope $_.Scope -Force }
	}

if ((Test-Path -Path $ReportsFolder\logs) -eq $false) { New-Item -Path "$ReportsFolder\logs" -ItemType Directory -Force -ErrorAction SilentlyContinue }
[string]$Transcriptlog ="$ReportsFolder\logs\XDUsers_TransmissionLogs." + (get-date -Format yyyy.MM.dd-HH.mm) + ".log"
Write-Verbose "$((get-date -Format HH:mm:ss).ToString()) [Starting] Data Collection"
Start-Transcript -Path $Transcriptlog -IncludeInvocationHeader -Force -NoClobber
$timer = [Diagnostics.Stopwatch]::StartNew();


########################################
## Getting Credentials
#########################################


$CTXAdmin = Find-Credential | Where-Object target -Like "*Healthcheck" | Get-Credential -Store
if ($null -eq $CTXAdmin) {
    $AdminAccount = BetterCredentials\Get-Credential -Message "Admin Account: DOMAIN\Username for CTX HealthChecks"
    Set-Credential -Credential $AdminAccount -Target "Healthcheck" -Persistence LocalComputer -Description "Account used for ctx health checks" -Verbose
}
########################################
## Functions
#########################################

########################################
## Connect and get info
#########################################
$compareusers = Compare-ADUser -Username1 $Username1 -Username2 $Username2 -Verbose


########################################
## Setting some table color and settings
########################################

#region Table Settings
$TableSettings = @{
	Style          = 'stripe'
	HideFooter     = $true
	OrderMulti     = $true
	TextWhenNoData = 'No Data to display here'
}

$SectionSettings = @{
	HeaderBackGroundColor = 'white'
	HeaderTextAlignment   = 'center'
	HeaderTextColor       = 'red'
	BackgroundColor       = 'white'
	CanCollapse           = $true
}

$TableSectionSettings = @{
	HeaderTextColor       = 'white'
	HeaderTextAlignment   = 'center'
	HeaderBackGroundColor = 'red'
	BackgroundColor       = 'white'
}
#endregion

#######################
## Building the report
#######################

$HeddingText = "Compared Users on: " + (Get-Date -Format dd) + " " + (Get-Date -Format MMMM) + "," + (Get-Date -Format yyyy) + " " + (Get-Date -Format HH:mm)
New-HTML -TitleText "Compared Users Report"  -FilePath "$env:TEMP\userscompared.html" -ShowHTML {
    New-HTMLHeading -Heading h1 -HeadingText $HeddingText -Color Black
    New-HTMLSection -HeaderText 'User Details' @SectionSettings  -Content {
        New-HTMLSection -HeaderText $compareusers.User1Details.user1Headding @TableSectionSettings {New-HTMLTable @TableSettings -DataTable $compareusers.User1Details.userDetailList1 }
        New-HTMLSection -HeaderText $compareusers.User2Details.user2Headding @TableSectionSettings {New-HTMLTable @TableSettings -DataTable $compareusers.User2Details.userDetailList2 }
    }
    New-HTMLSection @SectionSettings -HeaderText 'Comparison of the User Groups'   -Content {
        New-HTMLSection -HeaderText $compareusers.User1Details.user1HeaddingMissing @TableSectionSettings {New-HTMLTable @TableSettings -DataTable $compareusers.User1Details.User1Missing }
        New-HTMLSection -HeaderText $compareusers.User1Details.user2HeaddingMissing @TableSectionSettings {New-HTMLTable @TableSettings -DataTable $compareusers.User2Details.User2Missing }
        New-HTMLSection -HeaderText 'Same Groups' @TableSectionSettings {New-HTMLTable @TableSettings -DataTable $compareusers.SameGroups}
    }
    New-HTMLSection @SectionSettings -HeaderText 'All User Groups'   -Content {
        New-HTMLSection -HeaderText $compareusers.User1Details.user1Headding @TableSectionSettings {New-HTMLTable @TableSettings -DataTable $compareusers.User1Details.allusergroups1  }
        New-HTMLSection -HeaderText  $compareusers.User2Details.user2Headding @TableSectionSettings {New-HTMLTable @TableSettings -DataTable $compareusers.User2Details.allusergroups2 }
    }
}

$timer.Stop()
$timer.Elapsed | Select-Object Days,Hours,Minutes,Seconds | Format-List
Stop-Transcript

} #end Function

