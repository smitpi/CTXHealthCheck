$XDUserPage = New-UDPage -Name "User Details" -Icon user -Content {
New-UDCollapsible -Items {
#region Single user Details Section
		New-UDCollapsibleItem -BackgroundColor '#E5E5E5'  -Endpoint {
			New-UDInput -Content {
				[System.Collections.ArrayList]$DomainList = @()
				$DomainList = $TrustedDomains | ForEach-Object { $_.fqdn }
				$DomainList.Insert(0, "Select a Domain")

				New-UDInputField -Name 'Username' -Type textbox -Placeholder 'User ID'
				New-UDInputField -Name 'UserDomain' -Values @($DomainList) -Type select -Placeholder 'User Domain'
			} -Endpoint {
				param($Username, $UserDomain)

				New-UDInputAction -Content @(
					$domaincreds = $TrustedDomains | Where-Object { $_.fqdn -like $UserDomain }
	    			$validuser = Get-FullUserDetail -UserToQuery $username  -DomainFQDN $domaincreds.fqdn -DomainCredentials $domaincreds.Credentials -RunAsPSRemote -PSRemoteServerName $CTXDDC -PSRemoteCredentials $CTXAdmin
	    			$UserDetail = $validuser.UserSummery.psobject.Properties | Select-Object -Property Name, Value

					New-UDLayout -Columns 2 -Content {
						New-UDGrid -Id 'UserGrid1'  -Headers @("Name", "Value") -Properties @("Name", "Value") -NoPaging -Endpoint { $UserDetail | Out-UDGridData }
									New-UDGrid -Id 'UserGrid2' -Headers @("SamAccountName", "GroupScope") -Properties @("SamAccountName", "GroupScope") -NoPaging -Endpoint { $validuser.AllUserGroups | Select-Object SamAccountName, GroupScope | Out-UDGridData }
								}

				)
			}

} -Title "Single user Details" -FontColor black
#endregion

#region Compare Two Users Section
New-UDCollapsibleItem -BackgroundColor '#E5E5E5' -Endpoint {
			New-UDInput -Title "Compare Users" -Content {
				[System.Collections.ArrayList]$DomainList = @()
				$DomainList = $TrustedDomains | ForEach-Object { $_.fqdn }
				$DomainList.Insert(0, "Select a Domain")
				New-UDInputField -Name 'Username1' -Type textbox -Placeholder 'First User ID'
				New-UDInputField -Name 'Username2' -Type textbox -Placeholder 'Second User ID'
				New-UDInputField -Name 'UserDomain' -Values @($DomainList) -Type select -Placeholder 'User Domain'
			} -Endpoint {
				param(
					[string]$Username1, [string]$Username2, $UserDomain)

				$domaincreds = $TrustedDomains | Where-Object { $_.fqdn -like $UserDomain }
				$compareUsers = Compare-ADUser -Username1 $Username1 -Username2 $Username2 -DomainFQDN $domaincreds.fqdn -DomainCredentials $domaincreds.Credentials -RunAsPSRemote -PSRemoteServerName $CTXDDC -PSRemoteCredentials $CTXAdmin -Verbose

				New-UDInputAction -Content  @(
					New-UDLayout -Columns 2 -Content {
						New-UDGrid -Title $compareusers.User1Details.user1Headding  -NoPaging -NoFilter  -Endpoint { $compareusers.User1Details.userDetailList1 | Out-UDGridData }
						New-UDGrid -Title $compareusers.User2Details.user2Headding  -NoPaging -NoFilter -Endpoint { $compareusers.User2Details.userDetailList2 | Out-UDGridData }
	    }
	    New-UDLayout -Columns 3 -Content {
		    New-UDGrid -Title $compareusers.User1Details.user1HeaddingMissing  -NoPaging -NoFilter -Endpoint { $compareusers.User1Details.User1Missing | Out-UDGridData }
						New-UDGrid -Title $compareusers.User2Details.user2HeaddingMissing  -NoPaging -NoFilter -Endpoint { $compareusers.User2Details.User2Missing | Out-UDGridData }
						New-UDGrid -Title 'Same Groups'  -NoPaging -NoFilter -Endpoint { $compareusers.SameGroups | Out-UDGridData }
					}
					New-UDLayout -Columns 2 -Content {
						New-UDGrid -Title $compareusers.User1Details.user1Headding  -NoPaging -NoFilter -Endpoint { $compareusers.User1Details.allusergroups1 | Out-UDGridData }
						New-UDGrid -Title $compareusers.User2Details.user2Headding  -NoPaging -NoFilter -Endpoint { $compareusers.User2Details.allusergroups2 | Out-UDGridData }
					}
				)
			}
} -Title "Compare Two Users" -FontColor black
#endregion

#region Check User Access In Citrix Section
New-UDCollapsibleItem -BackgroundColor '#E5E5E5' -Endpoint {
			New-UDInput -Content {
				[System.Collections.ArrayList]$DomainList = @()
				$DomainList = $TrustedDomains | ForEach-Object { $_.fqdn }
				$DomainList.Insert(0, "Select a Domain")
				New-UDInputField -Name 'Username' -Type textbox -Placeholder 'User ID'
				New-UDInputField -Name 'UserDomain' -Values @($DomainList) -Type select -Placeholder 'User Domain'
			} -Endpoint {
				param($Username, $UserDomain)
				New-UDInputAction -Content @(

					$domaincreds = $TrustedDomains | Where-Object { $_.fqdn -like $UserDomain }
					$UserDetail = Get-CitrixUserAccessDetail -Username $username -AdminServer $CTXDDC -DomainFQDN $domaincreds.fqdn -DomainCredentials $domaincreds.Credentials -RunAsPSRemote -PSRemoteServerName $CTXDDC -PSRemoteCredentials $CTXAdmin
					$userDetailList = $UserDetail.UserDetail.psobject.Properties | Select-Object -Property Name, Value
					$Desktops = $UserDetail.PublishedDesktops | Sort-Object -Property DesktopGroupName -Unique
					New-UDLayout -Columns 5 -Content {
						New-UDGrid -Title 'User details' -NoPaging -NoFilter -Endpoint { $userDetailList | Out-UDGridData }
						New-UDGrid -Title 'Current Applications' -NoPaging -NoFilter -Endpoint { ($UserDetail.AccessPublishedApps | Select-Object PublishedName) | Out-UDGridData }
						New-UDGrid -Title 'Current VDI' -NoPaging -NoFilter -Endpoint { ($UserDetail.DirectPublishedDesktops | Select-Object DNSName) | Out-UDGridData }
						New-UDGrid -Title 'Current Published Dekstops' -NoPaging -NoFilter -Endpoint { ($Desktops | Select-Object DesktopGroupName) | Out-UDGridData }
						New-UDGrid -Title 'Available Applications' -NoPaging -NoFilter -Endpoint { ($UserDetail.NoAccessPublishedApps | Select-Object PublishedName) | Out-UDGridData }
					}
				)
			}
} -Title "Check User Access In Citrix" -FontColor black
#endregion
} # Main Collapsible
} # Page
$XDUserPage
