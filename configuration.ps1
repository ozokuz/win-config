# Constants
$global:ExplorerRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\'
$global:StorageSenseRegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\StorageSense\'
$global:TimeZoneRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\'
$global:FileSystemRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\'
$global:AppModelUnlockRegistryKeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\'
$global:PersonalizeRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\'
$global:SearchRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\'
$global:UACRegistryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'

$global:QuickAccessLocation = "shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}"

# Functions
function RunRegular ([string]$taskName, [string]$command, [string]$argument, [ScriptBlock]$checkComplete) {
  $action = New-ScheduledTaskAction -Execute $command -Argument $argument
  Register-ScheduledTask -TaskName $taskName -Action $action | Out-Null
  Start-ScheduledTask $taskName | Out-Null
  $complete = $false
  do {
    $complete = (&$checkComplete)
    if (-not ($complete)) {
      Start-Sleep 1
    }
  } until ($complete)
  Unregister-ScheduledTask $taskName -Confirm:$false | Out-Null
}

function SymbolicLink($source, $path) {
  New-Item -Type SymbolicLink -Value $source -Path $path | Out-Null
}

function LogStep($message) {
  Write-Output "$message`r`n"
}

# Start
LogStep "Starting Configuration"

# Disable UAC
LogStep "Disabling UAC"
Set-ItemProperty -Path $global:UACRegistryPath -Name 'ConsentPromptBehaviorAdmin' -Value 0

# Registry Edits
LogStep "Applying Registry Edits"

# Hide Desktop Icons
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'HideIcons' -Value 1
# Hide Taskbar Search Box
Set-ItemProperty -Path $global:SearchRegistryPath -Name 'SearchboxTaskbarMode' -Value 0
# Hide Task View Button
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'ShowTaskViewButton' -Value 0
# Hide Widgets Button
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'TaskbarDa' -Value 0
# Start explorer in This PC
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'LaunchTo' -Value 1
# Show File Extensions
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'HideFileExt' -Value 0
# Show Hidden Files
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'Hidden' -Value 1
# Dark Mode
Set-ItemProperty -Path $global:PersonalizeRegistryPath -Name 'AppsUseLightTheme' -Value 0
Set-ItemProperty -Path $global:PersonalizeRegistryPath -Name 'SystemUsesLightTheme' -Value 0
# Disable Storage Sense
if (-not (Test-Path -Path $global:StorageSenseRegistryPath)) {
  New-Item -Path $global:StorageSenseRegistryPath -Force | Out-Null
}
Set-ItemProperty -Path $global:StorageSenseRegistryPath -Name 'AllowStorageSenseGlobal' -Value 1
# Enable Long Paths
Set-ItemProperty -Path $global:FileSystemRegistryPath -Name 'LongPathsEnabled' -Value 1
# Use UTC Clock
Set-ItemProperty -Path $global:TimeZoneRegistryPath -Name 'RealTimeIsUniversal' -Value 1
# Enable Developer Mode
if (-not (Test-Path -Path $global:AppModelUnlockRegistryKeyPath)) {
  New-Item -Path $global:AppModelUnlockRegistryKeyPath -Force | Out-Null
}
Set-ItemProperty -Path $global:AppModelUnlockRegistryKeyPath -Name 'AllowDevelopmentWithoutDevLicense' -Value 1

LogStep "Registry Edits Applied, Restarting Explorer"
Stop-Process -ProcessName Explorer

# Remove Default Apps
LogStep "Removing Default Apps"
$apps = @("Clipchamp", "549981C3F5F10", "BingNews", "BingWeather", "MicrosoftStickyNotes", "MicrosoftOfficeHub", "Todos", "WindowsFeedbackHub", "WindowsMaps", "WindowsSoundRecorder", "QuickAssist", "windowscommunicationsapps", "GetHelp", "Getstarted")
Get-AppxPackage -AllUsers | Where-Object { $apps -contains $_.Name } | Remove-AppxPackage -AllUsers
LogStep "Removal Complete"

# Install Git
LogStep "Installing Git"
if (-not (Test-Path -Path $env:ProgramFiles\Git)) {
  winget install -e Git.Git -s winget
}
LogStep "`r`nGit Installed"

# Clone win-config
LogStep "Cloning config"
function ConfigCloned {
  Test-Path "$env:USERPROFILE\win-config\run.ps1" -PathType Leaf
  Start-Sleep 2
}
if (-not(ConfigCloned)) {
  RunRegular -taskName "CloneWinConfigRepo" -command "$env:ProgramFiles\Git\bin\git.exe" -argument "clone https://github.com/ozokuz/win-config $env:USERPROFILE\win-config --branch simplified" -checkComplete $function:ConfigCloned
}

# Set Location
LogStep "Entering config"
Set-Location "$env:USERPROFILE\win-config"

# Create Folders
LogStep "Creating Folders"
Get-Content "$env:USERPROFILE\win-config\values\folders.txt" | ForEach-Object {
  $path = "$(Invoke-Expression $_)"
  if (-not (Test-Path -Path $path)) {
    New-Item -Path $path -ItemType Directory | Out-Null
  }
}
LogStep "Folders Created"

# Setup Quick Access Pins
LogStep "Setting up Quick Access Pins"
$o = New-Object -ComObject shell.application
($o.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | Where-Object { $_.name -notin @() }).InvokeVerb("unpinfromhome");
Get-Content "$env:USERPROFILE\win-config\values\quick-access.txt" | ForEach-Object {
  $o.Namespace("$(Invoke-Expression $_)").Self.InvokeVerb("pintohome")
}
LogStep "Quick Access Pins Set"

# Run OOSU
LogStep "Running OOSU"
$oosuPath = "$env:USERPROFILE\Tools\OOSU"
Invoke-WebRequest "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile "$oosuPath\OOSU10.exe"
& "$oosuPath\OOSU10.exe" "$env:USERPROFILE\win-config\values\ooshutup10.cfg" /quiet
LogStep "OOSU Complete"

# Install Scoop & Tools
LogStep "Installing Scoop & CLI Tools"
function ScoopInstalled { Test-Path "$env:USERPROFILE\scoop\.complete" -PathType Leaf }
RunRegular -taskName "ScoopSetup" -command "powershell.exe" -argument "$env:USERPROFILE\win-config\scripts\scoop.ps1" -checkComplete $function:ScoopInstalled
LogStep "Installation of Scoop & CLI Tools Completed"

# Install WSL
LogStep "Installing WSL"
wsl.exe --install
LogStep "`r`nWSL Installed"

# Install Apps
Write-Output "Installing Apps"
Get-Content "$env:USERPROFILE\win-config\values\winget.txt" | ForEach-Object {
  Write-Output "`r`nInstalling $_`r`n"
  winget install -e $_ -s winget
}
LogStep "`r`nApps Installed"

# Install Visual Studio Components
LogStep "Installing Visual Studio Components"
$vsBase = "${env:ProgramFiles(x86)}\Microsoft Visual Studio"
$vsArgs = "modify --productId Microsoft.VisualStudio.Product.Community --channelId VisualStudio.17.Release --quiet --norestart --config $env:USERPROFILE\win-config\values\vsconfig.json"
Start-Process -FilePath "$vsBase\Installer\setup.exe" -ArgumentList $vsArgs -Wait | Out-Null
$activeInstaller = Get-Process Setup -ErrorAction SilentlyContinue | Where-Object { $_Path -like "$vsBase*" } -ErrorAction SilentlyContinue | ForEach-Object { $_.EnableRaisingEvents = $true } -ErrorAction SilentlyContinue
if ($activeInstaller) {
  Wait-Process -Id ($activeInstaller | Select-Object -ExpandProperty Id) -Timeout 3600
}
LogStep "Visual Studio Components Installed"

# Setup Config Symlinks
LogStep "Setting up Config Symlinks"
Get-Content "$env:USERPROFILE\win-config\values\conf-paths.txt" | ForEach-Object {
  $path = "$(Invoke-Expression $_)"
  $dir = Split-Path -Path $path -Parent
  if (-not (Test-Path -Path $dir)) {
    New-Item -Path $dir -ItemType Directory | Out-Null
  }
  $file = Split-Path -Path $path -Leaf
  SymbolicLink -source "$env:USERPROFILE\win-config\configs\$file" -path $path
}
LogStep "Config Symlinks Set"

# Re-enable UAC
LogStep "Re-enabling UAC"
Set-ItemProperty -Path $global:UACRegistryPath -Name 'ConsentPromptBehaviorAdmin' -Value 5

# Complete
LogStep "Configuration Complete"
Read-Host -Prompt "Press Enter to exit"