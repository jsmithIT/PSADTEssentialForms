<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory = $false)]
	[ValidateSet('Install', 'Uninstall', 'Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory = $false)]
	[ValidateSet('Interactive', 'Silent', 'NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory = $false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory = $false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	##* Variables: Application
	[string]$appVendor = 'Continuing Education of the Bar'
	[string]$appName = 'Essential Forms'
	[string]$appVersion = '4.4.14.1'
	[string]$appArch = 'x86'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '3.0.3'
	[string]$appScriptDate = '2022.06.30'
	[string]$appScriptAuthor = 'KTeuton, CuBaker, JBSmith'

	##* Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = "$appName ($appVersion)"
	[string]$installTitle = "$appName ($appVersion)"

	##*===============================================
	##* ANCHOR: VARIABLES - Template
	##* Changeable Array(s)/Variable(s)
	##*===============================================
	# Template array(s)/variable(s) used within the PSADT.

	## Set variables to match script variables
	# These Variable(s) keep the spaces the PSADT script removes. These can and are used in titles, messages, logs and the PIRK information for the application being installed.
	$apVendor = $appVendor
	$apName = $appName
	$apversion = $appVersion
	$apScriptVersion = $appScriptVersion
	
	##* InstallationWelcomeCloseApps
	# Used with the PSADT 'Show-InstallationWelcome -CloseApps' function.
	# Mainly used in the Pre-Installation and Pre-Uninstallation phases.
	# This variable will tell users what needs to be closed during install/uninstall phases.
	$CloseApps = "EFDownloader=Essential Forms Downloader,EFWin32=Essential Forms"
    
	##* Prerequisite Application install parameters. 
	# Prerequisite application 1 name.
	#$PrereqApp1Name = ""
	# Prerequisite application 1 install path.
	#$PrereqApp1InstallPath = ""
	# Prerequisite application 1 install parameters.
	#$PrereqApp1InstallParam = ""

	##* Application install parameters.
	# 64-bit application
	# 64-bit application install name.
	#$64bitAppInstallName = ""
	# Application install Path.
	#$64bitAppInstallPath = ""
	# Application  install parameters.
	#$64bitAppInstallParam = "REBOOT=ReallySuppress /QN" 

	# 32-bit application
	# 32-bit application install name.
	$32bitAppInstallName = "Essential Forms"
	# Application install Path.
	$32bitAppInstallPath = "$PSScriptRoot\Files\$apversion\setup.exe"
	# Application install parameters.
	$32bitAppInstallParam = "/s /f1`"$PSScriptRoot\Files\Response Files\Install.iss`""

	##* Remove Application Names 
	# Mainly used in the Pre-Installation, Pre-Uninstallation, Uninstallation and Post-Uninstallation phases.
	# These scalable Array(s)/Variable(s) are used to remove previous application(s) by name.
	#$RemoveAppNamesMSI = @("Essential Forms")
	$RemoveAppNamesEXE = @("Essential Forms")

	##* Application uninstall parameters.
	# 64-bit application
	# 64-bit application uninstall name.
	#$64bitAppUninstallName = ""
	# Application uninstall path.
	#$64bitAppUninstallPath = ""
	# Application uninstall parameters.
	#$64bitAppUninstallParam = ""

	# 32-bit application
	# 32-bit application uninstall name.
	$32bitAppUninstallName = "Essential Forms"
	# Application uninstall path.
	$32bitAppUninstallPath = "$PSScriptRoot\Files\$apversion\setup.exe"
	# Application uninstall parameters.
	$32bitAppUninstallParam = "/s /f1`"$PSScriptRoot\Files\Response Files\Uninstall.iss`""

	##* Application Settings File Name
	# Names of files used for application settings.
	#[string[]]$appSettingsNames = @("")

	##* Application Settings Directory
	# Directory where application settings reside.
	$appSettingsDir = "$Env:ProgramData\Tuolumne County\Application Settings\Essential Forms"

	##*===============================================
	##* ANCHOR: VARIABLES - Author
	##* Changeable Array(s)/Variable(s)
	##*===============================================
	# If the template array(s)/variable(s) aren't enough, add more array(s)/variable(s) here.

	##* Application update parameters
	# 32-bit application
	# 32-bit application update name.
	$32bitAppUpdateName = "Essential Forms" 
	# Application update path.
	$32bitAppUpdatePath = "$PSScriptRoot\Files\$apversion\setup.exe"
	# Application update parameters.
	$32bitAppUpdateParam = "/s /f1`"$PSScriptRoot\Files\Response Files\Update.iss`""

	##* Application Install Directory
	# Directory where application is installed.
	$appInstallDir = "$Env:ProgramFiles\CEB\Essential Forms"

	##*===============================================
	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.3'
	[string]$deployAppScriptDate = '30/09/2020'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0) { [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* ANCHOR: PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		# Check if deployment is interactive. 
		# If yes (it is interactive), show install prompt.
		If ($DeployMode -eq "Interactive") {
			$dialog = (Show-InstallationPrompt -Message "Changes are going to be made to your device. `n `n Please save your work and close all windows. `n `n To defer the changes, click the defer button on the next screen." -Icon "Information" -PersistPrompt -ButtonMiddleText "OK")
		}

		# Check if user accepted the install prompt.
		# If yes (it was accepted), show close application(s) prompt. Do not allow application(s) to start during install. 
		If ($dialog -eq "OK") { 
			Show-InstallationWelcome -CloseApps "$CloseApps" -MinimizeWindows $false -PersistPrompt -DeferDays "3" -BlockExecution -AllowDefer -DeferTimes "3"
		}

		# For each item in the array...
		# Check if previous EXE versions of application are installed.  
		# If application is installed, uninstall previous EXE versions of application.
		# If uninstall failed, log results. Exit script. 
		# Else, log results from check.
		Foreach ($RemoveAppNameEXE in $RemoveAppNamesEXE) {
			# Check if previous EXE versions of application are installed.  
			$RemoveAppNamesEXECheck = Get-InstalledApplication -Name "$RemoveAppNameEXE"
			If ($null -ne $RemoveAppNamesEXECheck) {
				# Uninstall previous EXE versions of application(s).      
				Try {
					Execute-Process -FilePath "$32bitAppUninstallPath" -Arguments "$32bitAppUninstallParam"
				}
				# If uninstall failed, log results. Exit script.
				Catch [System.Exception] {
					Write-Log -Message "Uninstalling previous EXE versions of $RemoveAppNameEXE failed with error: $_."
					Write-Log -Message "Exiting script with error."
					Exit-Script -ExitCode 1627
				}
			}
		}

		# Check if previous versions of activesetup key exist.
		# If activesetup key exists, remove previous versions of activesetup key.
		# If removal failed, exit script. Log results.
		If (Test-Path -Path "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\Essential Forms - Default Data Location") {
			# Remove previous versions of activesetup key.
			Try {
				Set-ActiveSetup -Key "Essential Forms - Default Data Location" -PurgeActiveSetupKey
				Write-Log -Message "Removing of previous versions of activesetup key complete."
			}
			# If removal failed, exit script. Log results. 
			Catch [System.Exception] {
				Write-Log -Message "Removing of previous versions of activesetup key failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		# Else, log results from check. 
		Else {  
			Write-Log -Message "Previous versions of activesetup key do not exist."        
		}
	
		# Check if previous versions of settings directory exist.
		# If settings directory exists, remove previous versions of settings directory.
		# If removal failed, log results. Exit script.
		If (Test-Path -Path "$appSettingsDir") {	
			# Remove previous versions of settings directory.
			Try {
				Remove-File -Path "$appSettingsDir" -Recurse
			}
			# If removal failed, log results. Exit script.
			Catch [System.Exception] {
				Write-Log -Message "Removing previous versions of settings directory failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		# Else, log results from check. 
		Else {  
			Write-Log -Message "Previous versions of settings directory do not exist."        
		}
		
		# Remove the registry data location for the application.
		# Create scriptblock of code to be run for registry changes.
		# Run the HKCU scriptblock.
		Try {
			# Scriptblock of HKCU changes.
			[scriptblock]$RegistryChanges = {
				# Remove the registry data location for the application.
				Remove-RegistryKey -Key "HKCU:Software\Essential Publishers\Essential Forms" -Recurse -SID $UserProfile.SID
			}
			# Run the script block, emulating through all past, present and future accounts.
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $RegistryChanges
		}
		Catch [System.Exception] {
			Write-Log -Message "Removing the registry data location for the application failed with error: $_."
			Write-Log -Message "Exiting script with error."
			Exit-Script -ExitCode 1627
		}

		# Check if previous versions of package information registry key (PIRK) exist. 
		# If package information registry key (PIRK) exists, remove previous versions of package information registry key (PIRK).
		# If removal failed, log results. Exit script. 
		# Else, log results from check.
		If (Test-Path -Path "HKLM:SOFTWARE\Tuolumne County\Package Information\$apName*") { 
			# Remove previous versions of package information registry key (PIRK).
			Try {
				Write-Log -Message "Previous versions of package information registry key (PIRK) exist. Removing..."
				Remove-Item -Path "HKLM:SOFTWARE\Tuolumne County\Package Information\$apName*" -Force
				Write-Log -Message "Removing previous versions of package information registry key (PIRK) complete."
			}
			# If removal failed, log results. Exit script. 
			Catch [System.Exception] {
				Write-Log -Message "Removing previous versions of package information registry key (PIRK) failed with error: $_"
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		# Else, log results from check. 
		Else { 
			Write-Log -Message "Previous versions of package information registry key (PIRK) do not exist."  
		}

		##*===============================================
		##* ANCHOR: INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		# Install application(s). 
		# If install failed, log results. Exit script.
		Try {
			# Show installation progress message window.
			Show-InstallationProgress -StatusMessage "Installing `n `n $apName ($apversion) `n `n Please Wait..." 
			Execute-Process -FilePath "$32bitAppInstallPath" -Arguments "$32bitAppInstallParam"
			Write-Log -Message "Installing $apName ($apversion) complete." 


		}
		# If install failed, log results. Exit script.
		Catch [System.Exception] {
			Write-Log -Message "Installing $apName ($apversion) failed with error: $_."
			Write-Log -Message "Exiting script with error."
			Exit-Script -ExitCode 1627
		}

		# Install application(s) update(s). 
		# If install failed, log results. Exit script.
		Try {
			Write-Log -Message "Upgrading $apName."
			# Show installation progress message window.
			Show-InstallationProgress -StatusMessage "Upgrading `n `n $apName `n `n Please Wait..." 
			Execute-Process -FilePath "$32bitAppUpdatePath" -Arguments "$32bitAppUpdateParam"
			Write-Log -Message "Upgrading $apName complete." 
		}
		# If install failed, log results. Exit script.
		Catch [System.Exception] {
			Write-Log -Message "Installing $apName ($apversion) failed with error: $_."
			Write-Log -Message "Exiting script with error."
			Exit-Script -ExitCode 1627
		}

		<#
		# For each item in the array...
		# Check if previous EXE versions of application(s) are installed.  
		# If previous versions of application(s) are not installed, install application(s).
		# If install failed, log results. Exit script.
		# Else, the application is already installed. 
		# Update the already isntalled applciation.
		# If update failed, log results. Exit script.
		Foreach ($RemoveAppNameEXE in $RemoveAppNamesEXE) {
			# Check if previous EXE versions of application are not installed.  
			$RemoveAppNamesEXECheck = Get-InstalledApplication -Name "$RemoveAppNameEXE"
			If ($null -eq $RemoveAppNamesEXECheck) {
				# If previous versions of application(s) are not installed, install application(s).   
				Try {
					Write-log -Message "Installing $apName ($apversion)."
					# Show installation progress message window.
					Show-InstallationProgress -StatusMessage "Installing `n `n $apName ($apversion) `n `n Please Wait..." 
					Execute-Process -FilePath "$32bitAppInstallPath" -Arguments "$32bitAppInstallParam"
					Write-Log -Message "Installing $apName ($apversion) complete." 
				}
				# If install failed, log results. Exit script.
				Catch [System.Exception] {
					Write-Log -Message "Installing $apName ($apversion) failed with error: $_."
					Write-Log -Message "Exiting script with error."
					Exit-Script -ExitCode 1627
				}
			}
			# Else, the application is already installed. 
			# Update the already isntalled applciation.
			# If update failed, log results. Exit script.
			Else {
				# Update the already isntalled applciation.
				Try {  
					Write-Log -Message "Previous EXE versions of $apName are installed. Upgrading to $apName ($apversion)."
					# Show installation progress message window.
					Show-InstallationProgress -StatusMessage "Upgrading to `n `n $apName ($apversion) `n `n Please Wait..." 
					Execute-Process -FilePath "$32bitAppUpdatePath" -Arguments "$32bitAppUpdateParam"
					Write-Log -Message "Upgrading to $apName ($apversion) complete." 
				}
				# If update failed, log results. Exit script.
				Catch [System.Exception] {
					Write-Log -Message "Upgrading to $apName ($apversion) failed with error: $_."
					Write-Log -Message "Exiting script with error."
					Exit-Script -ExitCode 1627
				}
			}
		}
		#>

		##* Every package should have a package information registry key (PIRK), which details what the $apversion and $apScriptVErsion are, along with any other information.
		# Create package information registry key (PIRK).
		# If creation failed, log results. Exit script.
		Try {
			Write-Log -Message "Creating package information registry key (PIRK)."
			Set-RegistryKey -Key "HKLM:Software\Tuolumne County\Package Information" -Name "Readme" -Value "These Package Information Registry Keys (PIRKs) are used for SCCM application detection. Please do not modify unless you know what you are doing." -Type String
			Set-RegistryKey -Key "HKLM:Software\Tuolumne County\Package Information\$apName ($apversion)" -Name "apVersion" -Value "$apversion" -Type String
			Set-RegistryKey -Key "HKLM:Software\Tuolumne County\Package Information\$apName ($apversion)" -Name "apScriptVersion" -Value "$apScriptVErsion" -Type String
			Write-Log -Message "Creating package information registry key (PIRK) complete." 
		}
		# If creation failed, log results. Exit script.
		Catch [System.Exception] {
			Write-Log -Message "Creating package information registry key (PIRK) failed with error: $_."
			Write-Log -Message "Exiting script with error."
			Exit-Script -ExitCode 1627
		}

		##*===============================================
		##* ANCHOR: POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		# Set rights for application directory.
		# If setting rights failed, log results. Exit script.
		Try {
			Write-Log -Message "Setting rights for application directory."
			Set-Rights -Path "$appInstallDir"
			Write-Log -Message "Setting rights for application directory complete."
		}
		# If setting rights failed, log results. Exit script.
		Catch [System.Exception] {
			Write-Log -Message "Setting rights for application directory failed with error: $_."
			Write-Log -Message "Exiting script with error."
			Exit-Script -ExitCode 1627
		}

		# Copy application settings to settings directory.
		# If copy failed, log results. Exit script.
		If ($envComputerName -like "CC*") {
			Try {
				Write-Log -Message "Copying application settings to settings directory." 
				Copy-File -Path "$dirFiles\Data Location Setters\CC\Essential Forms Data Location.EXE" -Destination "$appSettingsDir" -Recurse
			}
			# If copy failed, log results. Exit script.
			Catch [System.Exception] {
				Write-Log -Message "Copying application settings to settings directory failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		ElseIf ($envComputerName -like "CWS*") {
			Try {
				Write-Log -Message "Copying application settings to settings directory." 
				Copy-File -Path "$dirFiles\Data Location Setters\CWS\Essential Forms Data Location.EXE" -Destination "$appSettingsDir" -Recurse
			}
			# If copy failed, log results. Exit script.
			Catch [System.Exception] {
				Write-Log -Message "Copying application settings to settings directory failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		ElseIf ($envComputerName -like "DSS*") {
			Try {
				Write-Log -Message "Copying application settings to settings directory." 
				Copy-File -Path "$dirFiles\Data Location Setters\DSS\Essential Forms Data Location.EXE" -Destination "$appSettingsDir" -Recurse
			}
			# If copy failed, log results. Exit script.
			Catch [System.Exception] {
				Write-Log -Message "Copying application settings to settings directory failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		ElseIf ($envComputerName -like "ORR*") {
			Try {
				Write-Log -Message "Copying application settings to settings directory." 
				Copy-File -Path "$dirFiles\Data Location Setters\ORR\Essential Forms Data Location.EXE" -Destination "$appSettingsDir" -Recurse
			}
			# If copy failed, log results. Exit script.
			Catch [System.Exception] {
				Write-Log -Message "Copying application settings to settings directory failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
        
		# Setup activesetup to import application settings for all users.
		# If setting up activesetup failed, exit script. Log results.
		Try {
			Write-Log -Message "Setting up activesetup."
			Set-ActiveSetup -StubExePath "$appSettingsDir\Essential Forms Data Location.EXE" -Description "Essential Forms - Default Data Location" -Key "Essential Forms - Default Data Location"
			Write-Log -Message "Setting up activesetup complete."
		}
		# If setting up activesetup failed, exit script. Log results. 
		Catch [System.Exception] {
			Write-Log -Message "Setting up activesetup failed with error: $_."
			Write-Log -Message "Exiting script with error."
			Exit-Script -ExitCode 1627
		}

		# Show install completed prompt.
		Write-Log -Message "Showing installation completed prompt."
		Show-InstallationPrompt -Title "Install Completed" -Message "Your installation of $apName ($apversion) has completed.`n `n Please close any remaining prompts/windows that may have opened.`n `n Questions or issues? `n Please contact the IT Service Desk: `n ITServiceDesk@co.tuolumne.ca.us" -Icon "Information" -PersistPrompt -ButtonMiddleText "OK"		

	}
	ElseIf ($deploymentType -ieq 'Uninstall') {
		##*===============================================
		##* ANCHOR: PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		# Check if deployment is interactive.
		# If yes (it is interactive), show close application(s) prompt. Do not allow application(s) to start during install. 
		If ($DeployMode -eq "Interactive") {
			Show-InstallationWelcome -CloseApps "$CloseApps" -MinimizeWindows $false -PersistPrompt -DeferDays "3" -BlockExecution -AllowDefer -DeferTimes "3"
		}

		##*===============================================
		##* ANCHOR: UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# For each item in the array...
		# Check if previous EXE versions of application are installed.  
		# If application is installed, uninstall previous EXE versions of application.
		# If uninstall failed, log results. Exit script. 
		# Else, log results from check.
		Foreach ($RemoveAppNameEXE in $RemoveAppNamesEXE) {
			# Check if previous EXE versions of application are installed.  
			$RemoveAppNamesEXECheck = Get-InstalledApplication -Name "$RemoveAppNameEXE"
			If ($null -ne $RemoveAppNamesEXECheck) {
				# Uninstall previous EXE versions of application(s).      
				Try {
					Execute-Process -FilePath "$32bitAppUninstallPath" -Arguments "$32bitAppUninstallParam"
				}
				# If uninstall failed, log results. Exit script.
				Catch [System.Exception] {
					Write-Log -Message "Uninstalling previous EXE versions of $RemoveAppNameEXE failed with error: $_."
					Write-Log -Message "Exiting script with error."
					Exit-Script -ExitCode 1627
				}
			}
		}

		# Check if previous versions of package information registry key (PIRK) exist. 
		# If package information registry key (PIRK) exists, remove previous versions of package information registry key (PIRK).
		# If removal failed, log results. Exit script. 
		# Else, log results from check.
		If (Test-Path -Path "HKLM:SOFTWARE\Tuolumne County\Package Information\$apName*") { 
			# Remove previous versions of package information registry key (PIRK).
			Try {
				Write-Log -Message "Previous versions of package information registry key (PIRK) exist. Removing..."
				Remove-Item -Path "HKLM:SOFTWARE\Tuolumne County\Package Information\$apName*" -Force
				Write-Log -Message "Removing previous versions of package information registry key (PIRK) complete."
			}
			# If removal failed, log results. Exit script. 
			Catch [System.Exception] {
				Write-Log -Message "Removing previous versions of package information registry key (PIRK) failed with error: $_"
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		# Else, log results from check. 
		Else { 
			Write-Log -Message "Previous versions of package information registry key (PIRK) do not exist."  
		}

		##*===============================================
		##* ANCHOR: POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		# Check if previous versions of activesetup key exist.
		# If activesetup key exists, remove previous versions of activesetup key.
		# If removal failed, exit script. Log results.
		If (Test-Path -Path "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\Essential Forms - Default Data Location") {
			# Remove previous versions of activesetup key.    
			Try {
				Set-ActiveSetup -Key "Essential Forms - Default Data Location" -PurgeActiveSetupKey
				# NOTE: test in log
				Write-Log -Message "Removing of previous versions of activesetup key complete."
			}
			# If removal failed, exit script. Log results. 
			Catch [System.Exception] {
				Write-Log -Message "Removing of previous versions of activesetup key failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		# Else, log results from check. 
		Else {  
			Write-Log -Message "Previous versions of activesetup key do not exist."        
		}
	
		# Check if previous versions of settings directory exist.
		# If settings directory exists, remove previous versions of settings directory.
		# If removal failed, log results. Exit script.
		If (Test-Path -Path "$appSettingsDir") {	
			# Remove previous versions of settings directory.
			Try {
				Remove-File -Path "$appSettingsDir" -Recurse
			}
			# If removal failed, log results. Exit script.
			Catch [System.Exception] {
				Write-Log -Message "Removing previous versions of settings directory failed with error: $_."
				Write-Log -Message "Exiting script with error."
				Exit-Script -ExitCode 1627
			}
		}
		# Else, log results from check. 
		Else {  
			Write-Log -Message "Previous versions of settings directory do not exist."        
		}
		
		# Remove the registry data location for the application.
		# Create scriptblock of code to be run for registry changes.
		# Run the HKCU scriptblock.
		Try {
			# Scriptblock of HKCU changes.
			[scriptblock]$RegistryChanges = {
				# Remove the registry data location for the application.
				Remove-RegistryKey -Key "HKCU:Software\Essential Publishers\Essential Forms" -Recurse -SID $UserProfile.SID
			}
			# Run the script block, emulating through all past, present and future accounts.
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $RegistryChanges
		}
		Catch [System.Exception] {
			Write-Log -Message "Removing the registry data location for the application failed with error: $_."
			Write-Log -Message "Exiting script with error."
			Exit-Script -ExitCode 1627
		}

	}
	ElseIf ($deploymentType -ieq 'Repair') {
		##*===============================================
		##* ANCHOR: PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* ANCHOR: REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
		# <Perform Repair tasks here>

		##*===============================================
		##* ANCHOR: POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>

	}
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
