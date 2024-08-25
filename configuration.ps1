# Constants
$global:ExplorerRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\'
$global:StorageSenseRegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\StorageSense\'
$global:TimeZoneRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\'
$global:FileSystemRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\'
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
LogStep "Disabling UAC while configuring"
Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 0

# Registry Edits
LogStep "Applying Registry Edits"
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'HideIcons' -Value 1
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'LaunchTo' -Value 1
if (-not (Test-Path -Path $global:StorageSenseRegistryPath)) {
  New-Item -Path $global:StorageSenseRegistryPath -Force | Out-Null
}
Set-ItemProperty -Path $global:StorageSenseRegistryPath -Name 'AllowStorageSenseGlobal' -Value 1
Set-ItemProperty -Path $global:FileSystemRegistryPath -Name 'LongPathsEnabled' -Value 1
Set-ItemProperty -Path $global:TimeZoneRegistryPath -Name 'RealTimeIsUniversal' -Value 1
LogStep "Registry Edits Applied, Restarting Explorer"
taskkill /F /IM explorer.exe | Out-Null
Start-Process explorer.exe

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
LogStep "Installing Apps"
winget configure "$env:USERPROFILE\win-config\values\main.dsc.yml" --accept-configuration-agreements
LogStep "Apps Installed"

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

# Restore UAC
LogStep "Restoring UAC"
Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 1

# Complete
LogStep "Configuration Complete"
Read-Host -Prompt "Press Enter to exit"