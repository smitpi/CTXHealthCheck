#
# Module manifest for module 'XDHealthCheck'
#
# Generated by: Pierre Smit
#
# Generated on: 2021/10/16
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'XDHealthCheck.psm1'

# Version number of this module.
ModuleVersion = '0.2.3'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '39f9295c-353e-4bb7-aee5-0c600dfd5eba'

# Author of this module
Author = 'Pierre Smit'

# Company or vendor of this module
CompanyName = 'iOCO Tech'

# Copyright statement for this module
Copyright = '(c) 2019 Pierre Smit. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Creates daily health check, and config reports for your on premis Citrix farm.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('ImportExcel', 
               'PSWriteHTML', 
               'PSWriteColor', 
               'BetterCredentials')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Get-CitrixConfigurationChange', 'Get-CitrixFarmDetail', 
               'Get-CitrixLicenseInformation', 'Get-CitrixObjects', 
               'Get-CitrixServerEventLog', 'Get-CitrixServerPerformance', 
               'Get-CitrixSingleServerPerformance', 'Get-CitrixWebsiteStatus', 
               'Get-RDSLicenseInformation', 'Get-StoreFrontDetail', 
               'Import-ParametersFile', 'Install-BasePSModules', 
               'Install-ParametersFile', 'Start-CitrixAudit', 
               'Start-CitrixHealthCheck'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'citrix','ctx'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        IconUri = 'https://ioco.tech/wp-content/uploads/2020/10/ioco-logo-2020.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'Updated [16/10/2021_23:29] Getting ready to upload'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

